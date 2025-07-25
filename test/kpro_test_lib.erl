%%%   Copyright (c) 2018-2021, Klarna Bank AB (publ)
%%%
%%%   Licensed under the Apache License, Version 2.0 (the "License");
%%%   you may not use this file except in compliance with the License.
%%%   You may obtain a copy of the License at
%%%
%%%       http://www.apache.org/licenses/LICENSE-2.0
%%%
%%%   Unless required by applicable law or agreed to in writing, software
%%%   distributed under the License is distributed on an "AS IS" BASIS,
%%%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%%   See the License for the specific language governing permissions and
%%%   limitations under the License.
%%%
-module(kpro_test_lib).

-export([ get_endpoints/1
        , guess_protocol/1
        ]).

-export([ get_topic/0
        , get_topic_lat/0
        ]).

-export([ sasl_config/0
        , sasl_config/1
        ]).

-export([ connection_config/1
        , ssl_options/0
        ]).

-export([ with_connection/1
        , with_connection/2
        , with_connection/3
        , with_connection/4
        ]).

-export([ is_kafka_09/0
        , get_kafka_version/0
        , parse_rsp/1
        ]).

-export([list_offset/5]).

-include("kpro_private.hrl").

-type conn() :: kpro_connection:connection().
-type config() :: kpro_connection:config().

get_kafka_version() ->
  case is_kafka_09() of
    true -> ?KAFKA_0_9;
    false -> with_connection(fun get_kafka_version/1)
  end.

is_kafka_09() ->
  case osenv("KAFKA_VERSION") of
    "0.9" ++ _ -> true;
    _ -> false
  end.

connection_config(Config) when is_map(Config) ->
  case is_kafka_09() of
    true -> Config#{query_api_versions => false};
    false -> Config
  end;
connection_config(Protocol) when is_atom(Protocol) ->
  C = do_connection_config(Protocol),
  connection_config(C).

get_endpoints(Protocol) ->
  case osenv("KPRO_TEST_KAFKA_ENDPOINTS") of
    undefined -> default_endpoints(Protocol);
    Str -> kpro:parse_endpoints(Protocol, Str)
  end.

get_topic() ->
  case osenv("KPRO_TEST_KAFKA_TOPIC_NAME") of
    undefined -> <<"test-topic">>;
    Str -> iolist_to_binary(Str)
  end.

get_topic_lat() ->
  case osenv("KPRO_TEST_KAFKA_TOPIC_LAT_NAME") of
    undefined -> <<"test-topic-lat">>;
    Str -> iolist_to_binary(Str)
  end.

sasl_config() ->
  sasl_config(rand_sasl()).

sasl_config(Alg) ->
  case is_kafka_09() of
    true ->
      undefined;
    false ->
      do_sasl_config(Alg)
  end.

do_sasl_config(plain_file) ->
  {plain, get_sasl_file()};
do_sasl_config(file) ->
  {rand_sasl(), get_sasl_file()};
do_sasl_config(Mechanism) ->
  {User, Pass} = read_user_pass(),
  {Mechanism, User, Pass}.

get_sasl_file() ->
  case osenv("KPRO_TEST_KAFKA_SASL_USER_PASS_FILE") of
    undefined ->
      F = "/tmp/kpro-test-sasl-plain-user-pass",
      ok = file:write_file(F, "alice\necila\n"),
      F;
    File ->
      File
  end.

read_user_pass() ->
  F = get_sasl_file(),
  {ok, Lines0} = file:read_file(F),
  Lines = binary:split(Lines0, <<"\n">>, [global]),
  [User, Pass] = lists:filter(fun(Line) -> Line =/= <<>> end, Lines),
  {User, Pass}.

-spec with_connection(fun((conn()) -> any())) -> any().
with_connection(WithConnFun) ->
  with_connection(fun kpro:connect_any/2, WithConnFun).

-spec with_connection(fun(([kpro:endpoint()], config()) -> {ok, conn()}),
                      fun((conn()) -> any())) -> any().
with_connection(ConnectFun, WithConnFun) ->
  with_connection(connection_config(plaintext), ConnectFun, WithConnFun).

with_connection(Config, ConnectFun, WithConnFun) ->
  Endpoints = get_endpoints(guess_protocol(Config)),
  with_connection(Endpoints, Config, ConnectFun, WithConnFun).

with_connection(Endpoints, Config, ConnectFun, WithConnFun) ->
  {ok, Pid} = ConnectFun(Endpoints, Config),
  with_connection_pid(Pid, WithConnFun).

-spec parse_rsp(kpro:rsp()) -> term().
parse_rsp(#kpro_rsp{ api = list_offsets
                   , msg = Msg
                   }) ->
  case get_partition_rsp(Msg) of
    #{offsets := [Offset]} = M -> M#{offset => Offset};
    #{offset := _} = M -> M
  end;
parse_rsp(#kpro_rsp{ api = produce
                   , msg = Msg
                   }) ->
  get_partition_rsp(Msg);
parse_rsp(#kpro_rsp{ api = fetch
                   , vsn = Vsn
                   , msg = Msg
                   }) ->
  EC1 = kpro:find(error_code, Msg, ?no_error),
  SessionID = kpro:find(session_id, Msg, 0),
  {Header, Batches, EC2} =
    case kpro:find(responses, Msg) of
      [] ->
        %% a session init without data
        {undefined, [], ?no_error};
      _ ->
        PartitionRsp = get_partition_rsp(Msg),
        Header0 = kpro:find(partition_header, PartitionRsp),
        Records = kpro:find(record_set, PartitionRsp),
        ECx = kpro:find(error_code, Header0),
        {Header0, decode_batches(Vsn, Records), ECx}
    end,
  ErrorCode = case EC2 =:= ?no_error of
                true  -> EC1;
                false -> EC2
              end,
  #{ error_code => ErrorCode
   , session_id => SessionID
   , header => Header
   , batches => Batches
   };
parse_rsp(#kpro_rsp{ api = create_topics
                   , msg = Msg
                   }) ->
  error_if_any(kpro:find(topics, Msg));
parse_rsp(#kpro_rsp{ api = delete_topics
                   , msg = Msg
                   }) ->
  error_if_any(kpro:find(responses, Msg));
parse_rsp(#kpro_rsp{ api = create_partitions
                   , msg = Msg
                   }) ->
  error_if_any(kpro:find(topic_errors, Msg));
parse_rsp(#kpro_rsp{ api = describe_configs
                   , msg = Msg
                   }) ->
  Resources = kpro:find(resources, Msg),
  ok = error_if_any(Resources),
  Resources;
parse_rsp(#kpro_rsp{ api = alter_configs
                   , msg = Msg
                   }) ->
  error_if_any(kpro:find(resources, Msg));
parse_rsp(#kpro_rsp{msg = Msg}) ->
  Msg.

list_offset(Connection, Topic, Partition, Time, Timeout) ->
  {ok, Vsns} = kpro:get_api_versions(Connection),
  {_Min, Vsn} = maps:get(list_offsets, Vsns),
  Req = kpro_req_lib:list_offsets(Vsn, Topic, Partition, Time),
  {ok, Rsp} = kpro:request_sync(Connection, Req, Timeout),
  #{offset := Offset} = parse_rsp(Rsp),
  Offset.

%%%_* Internal functions =======================================================

decode_batches(Vsn, <<>>) when Vsn >= ?MIN_MAGIC_2_FETCH_API_VSN ->
  %% when it's magic v2, there is no incomplete batch
  [];
decode_batches(_Vsn, Bin) ->
  kpro:decode_batches(Bin).

get_partition_rsp(Struct) ->
  [TopicRsp] = kpro:find(responses, Struct),
  [PartitionRsp] = kpro:find(partition_responses, TopicRsp),
  PartitionRsp.

%% Return ok if all error codes are 'no_error'
%% otherwise return {error, Errors} where Errors is a list of error codes
error_if_any(Errors) ->
  Pred = fun(Struct) -> kpro:find(error_code, Struct) =/= ?no_error end,
  case lists:filter(Pred, Errors) of
    [] -> ok;
    Errs -> erlang:error(Errs)
  end.

do_connection_config(plaintext) ->
  #{};
do_connection_config(ssl) ->
  #{ssl => ssl_options()};
do_connection_config(sasl_ssl) ->
  #{ ssl => ssl_options()
   , sasl => sasl_config(plain)
   }.

ssl_options() ->
  CertDir = filename:join([code:lib_dir(?APPLICATION), "test", "certs"]),
  Fname = fun(Name) -> filename:join([CertDir, Name]) end,
  [ {keyfile,    Fname("client-key.pem")}
  , {certfile,   Fname("client-crt.pem")}
  , {verify,     verify_none}
  , {versions,   ['tlsv1.2']}
  ].

osenv(Name) ->
  case os:getenv(Name) of
    "" -> undefined;
    false -> undefined;
    Val -> Val
  end.

%% Guess protocol name from connection config.
guess_protocol(#{sasl := Sasl} = Config) when Sasl =/= undefined ->
  case maps:get(ssl, Config, false) of
    false -> erlang:error(<<"sasl_plaintext not supported in tests">>);
    _ -> sasl_ssl
  end;
guess_protocol(Config) ->
  case maps:get(ssl, Config, false) of
    false -> plaintext;
    _ -> ssl
  end.

default_endpoints(plaintext) -> [{localhost, 9092}];
default_endpoints(ssl) -> [{"localhost", 9093}];
default_endpoints(sasl_ssl) -> [{"localhost", 9094}].

with_connection_pid(Conn, Fun) ->
  try
    Fun(Conn)
  after
    unlink(Conn),
    kpro:close_connection(Conn)
  end.

rand_sasl() -> rand_elem([plain, scram_sha_256, scram_sha_512]).

rand_elem(L) -> lists:nth(rand:uniform(length(L)), L).

%% With a plaintext connection, try to query API versions
%% and guess kafka version from max API versions
%% NOTE: Assuming it's kafka 0.10 or later
get_kafka_version(Conn) ->
  {ok, Vsns} = kpro_connection:get_api_vsns(Conn),
  Signatures =
    [ {sasl_authenticate, no_such_api, ?KAFKA_0_10}
    , {produce, ?MIN_MAGIC_2_PRODUCE_API_VSN, ?KAFKA_0_11}
    , {delete_groups, no_such_api, ?KAFKA_1_0}
    ],
  Match = fun({API, Signature, KafkaVsn}) ->
              case maps:get(API, Vsns, no_such_api) of
                {_, Signature} -> KafkaVsn;
                Signature -> KafkaVsn;
                _ -> false
              end
          end,
  case get_first(Match, Signatures) of
    false -> ?KAFKA_1_1;
    GotIt -> GotIt
  end.

get_first(_Match, []) -> false;
get_first(Match, [Signature | Rest]) ->
  case Match(Signature) of
    false -> get_first(Match, Rest);
    GotIt -> GotIt
  end.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
