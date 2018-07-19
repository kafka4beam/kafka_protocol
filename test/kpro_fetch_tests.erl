%%%   Copyright (c) 2018, Klarna AB
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
-module(kpro_fetch_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro_private.hrl").

-define(TOPIC, kpro_test_lib:get_topic()).
-define(PARTI, 0).
-define(TIMEOUT, 5000).

-define(RAND_PRODUCE_BATCH_COUNT, 10).
-define(RAND_BATCH_SIZE, 50).
-define(RAND_KAFKA_VALUE_BYTES, 1024).

fetch_test_() ->
  {Min, Max} = get_api_vsn_range(),
  [{"version " ++ integer_to_list(V),
    fun() -> with_vsn(V) end} || V <- lists:seq(Min, Max)].

fetch_and_verify(_Connection, _Vsn, _BeginOffset, []) -> ok;
fetch_and_verify(Connection, Vsn, BeginOffset, Messages) ->
  Batch0 = do_fetch(Connection, Vsn, BeginOffset, rand_num(1000)),
  Batch = drop_older_offsets(BeginOffset, Batch0),
  [#kafka_message{offset = FirstOffset} | _] = Batch,
  ?assertEqual(FirstOffset, BeginOffset),
  Rest = validate_messages(Batch, Messages),
  #kafka_message{offset = NextBeginOffset} = lists:last(Batch),
  fetch_and_verify(Connection, Vsn, NextBeginOffset + 1, Rest).

%% kafka 0.9 may return messages having offset less than requested
%% in case the requested offset is in the middle of a compressed batch
drop_older_offsets(Offset, [#kafka_message{offset = O} | R] = ML) ->
  case Offset < O of
    true -> drop_older_offsets(Offset, R);
    false -> ML
  end.

validate_messages([], Rest) -> Rest;
validate_messages([#kafka_message{key = K, value = V} | R1], [Msg | R2]) ->
  ok = validate_message(K, V, Msg),
  validate_messages(R1, R2).

validate_message(K, V, {K, V}) -> ok;
validate_message(K, V, {_T, K, V}) -> ok;
validate_message(K, V, #{key := K, value := V}) -> ok;
validate_message(K, V, Wat) ->
  erlang:error(#{ fetched => {K, V}
                , produced => Wat
                }).

do_fetch(Connection, Vsn, BeginOffset, MaxBytes) ->
  Req = make_req(Vsn, BeginOffset, MaxBytes),
  {ok, Rsp} = kpro:request_sync(Connection, Req, ?TIMEOUT),
  #{ header := Header
   , batches := Batches
   } = kpro_test_lib:parse_rsp(Rsp),
  case Header of
    undefined -> ok;
    _ -> ?assertEqual(no_error, kpro:find(error_code, Header))
  end,
  case Batches of
    ?incomplete_batch(Size) ->
      do_fetch(Connection, Vsn, BeginOffset, Size);
    _ ->
      lists:append([Msgs || {_Meta, Msgs} <- Batches])
  end.

with_vsn(Vsn) ->
  with_connection(
    random_config(),
    fun(Connection) ->
        {BaseOffset, Messages} = produce_randomly(Connection),
        fetch_and_verify(Connection, Vsn, BaseOffset, Messages)
    end).

produce_randomly(Connection) ->
  produce_randomly(Connection, rand_num(?RAND_PRODUCE_BATCH_COUNT), []).

produce_randomly(_Connection, 0, Acc0) ->
  [{BaseOffset, _} | _] = Acc = lists:reverse(Acc0),
  {BaseOffset, lists:append([Msg || {_, Msg} <- Acc])};
produce_randomly(Connection, Count, Acc) ->
  {ok, Versions} = kpro:get_api_versions(Connection),
  {MinVsn, MaxVsn} = maps:get(produce, Versions),
  Vsn = case MinVsn =:= MaxVsn of
          true -> MinVsn;
          false -> MinVsn + rand_num(MaxVsn - MinVsn) - 1
        end,
  Opts = rand_produce_opts(),
  Batch = make_random_batch(rand_num(?RAND_BATCH_SIZE)),
  Req = kpro_req_lib:produce(Vsn, ?TOPIC, ?PARTI, Batch, Opts),
  {ok, Rsp} = kpro:request_sync(Connection, Req, ?TIMEOUT),
  #{ error_code := no_error
   , base_offset := Offset
   } = kpro_test_lib:parse_rsp(Rsp),
  produce_randomly(Connection, Count - 1, [{Offset, Batch} | Acc]).

rand_produce_opts() ->
  #{ compression => rand_element([no_compression, gzip, snappy])
   , required_acks => rand_element([leader_only, all_isr, 1, -1])
   }.

rand_num(N) -> (os:system_time() rem N) + 1.

rand_element(L) -> lists:nth(rand_num(length(L)), L).

make_req(Vsn, Offset, MaxBytes) ->
  Opts = #{ max_wait_time => 500
          , max_bytes => MaxBytes
          },
  kpro_req_lib:fetch(Vsn, ?TOPIC, ?PARTI, Offset, Opts).

random_config() ->
  Configs0 =
    [ kpro_test_lib:connection_config(plaintext)
    , kpro_test_lib:connection_config(ssl)
    ],
  Configs = case kpro_test_lib:is_kafka_09() of
              true -> Configs0;
              false -> [kpro_test_lib:connection_config(sasl_ssl) | Configs0]
            end,
  rand_element(Configs).

get_api_vsn_range() ->
  Config = kpro_test_lib:connection_config(plaintext),
  {ok, Versions} =
    with_connection(Config, fun(Pid) -> kpro:get_api_versions(Pid) end),
  maps:get(fetch, Versions).

with_connection(Config, Fun) ->
  ConnFun =
    fun(Endpoints, Cfg) ->
        kpro:connect_partition_leader(Endpoints, Cfg, ?TOPIC, ?PARTI)
    end,
  kpro_test_lib:with_connection(Config, ConnFun, Fun).

make_random_batch(Count) ->
  [#{ ts => kpro_lib:now_ts()
    , key => uniq_bin()
    , value => rand_bin()
    } || _ <- lists:seq(1, Count)].

uniq_bin() ->
  iolist_to_binary(lists:reverse(integer_to_list(os:system_time()))).

rand_bin() ->
  crypto:strong_rand_bytes(rand_num(?RAND_KAFKA_VALUE_BYTES)).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
