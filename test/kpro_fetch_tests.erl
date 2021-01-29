%%%   Copyright (c) 2018-2020, Klarna AB
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
-define(TOPIC_LAT, kpro_test_lib:get_topic_lat()).
-define(PARTI, 0).
-define(TIMEOUT, 5000).

-define(RAND_PRODUCE_BATCH_COUNT, 10).
-define(RAND_BATCH_SIZE, 50).
-define(RAND_KAFKA_VALUE_BYTES, 1024).

fetch_test_() ->
  {Min, Max} = get_api_vsn_range(?TOPIC),
  [{"version " ++ integer_to_list(V),
    fun() -> with_vsn_topic(V, ?TOPIC) end} || V <- lists:seq(Min, Max)].

fetch_lat_test_() ->
  case kpro_test_lib:is_kafka_09() of
    true -> [];
    false ->
      {Min, Max} = get_api_vsn_range(?TOPIC_LAT),
      [{"version " ++ integer_to_list(V),
        fun() -> with_vsn_topic(V, ?TOPIC_LAT) end} || V <- lists:seq(Min, Max)]
  end.

incremental_fetch_test() ->
  {_Min, Max} = get_api_vsn_range(?TOPIC),
  case Max >= 7 of
    true ->
      with_connection(
        random_config(),
        ?TOPIC,
        fun(Conn) -> test_incemental_fetch(Conn, Max) end);
    false -> ok
  end.

test_incemental_fetch(Connection, Vsn) ->
  %% resolve latest offset
  LatestOffset = kpro_test_lib:list_offset(Connection, ?TOPIC, ?PARTI,
                                           latest, 5000),
  %% session-id=0 and epoch=0 to initialize a session
  Req0 = kpro_req_lib:fetch(Vsn, ?TOPIC, ?PARTI, LatestOffset,
                            #{ session_id => 0
                             , session_epoch => 0
                             , max_bytes => 1
                             }),
  {ok, Rsp0} = kpro:request_sync(Connection, Req0, ?TIMEOUT),
  #{session_id := SessionId} = Rsp0#kpro_rsp.msg,
  #{header := Header0} = kpro_test_lib:parse_rsp(Rsp0),
  #{last_stable_offset := LatestOffset1} = Header0,
  ?assertEqual(LatestOffset, LatestOffset1),
  Req1 = kpro_req_lib:fetch(Vsn, ?TOPIC, ?PARTI, LatestOffset,
                            #{ session_id => SessionId
                             , session_epoch => 1 %% 0 + 1
                             , max_bytes => 1
                             , max_wait_time => 10 %% ms
                             }),
  {ok, Rsp1} = kpro:request_sync(Connection, Req1, ?TIMEOUT),
  ?assertMatch(#kpro_rsp{msg = #{ error_code := no_error
                                , session_id := SessionId
                                }}, Rsp1),
  %% No change since last fetch, assert nothing in response
  %% including topic-partition metadata.
  ?assertEqual([], maps:get(responses, Rsp1#kpro_rsp.msg)).

fetch_and_verify(_Connection, _Topic, _Vsn, _BeginOffset, []) -> ok;
fetch_and_verify(Connection, Topic, Vsn, BeginOffset, Messages) ->
  Batch0 = do_fetch(Connection, Topic, Vsn, BeginOffset, rand_num(1000)),
  Batch = drop_older_offsets(BeginOffset, Batch0),
  [#kafka_message{offset = FirstOffset} | _] = Batch,
  ?assertEqual(FirstOffset, BeginOffset),
  Rest = validate_messages(Topic, Vsn, Batch, Messages),
  #kafka_message{offset = NextBeginOffset} = lists:last(Batch),
  fetch_and_verify(Connection, Topic, Vsn, NextBeginOffset + 1, Rest).

%% kafka 0.9 may return messages having offset less than requested
%% in case the requested offset is in the middle of a compressed batch
drop_older_offsets(Offset, [#kafka_message{offset = O} | R] = ML) ->
  case Offset < O of
    true -> drop_older_offsets(Offset, R);
    false -> ML
  end.

validate_messages(_Topic, _FetchVsn, [], Rest) -> Rest;
validate_messages(Topic, FetchVsn,
                  [#kafka_message{ts_type = TType, ts = T, key = K, value = V} | R1],
                  [{ProduceVsn, LAT, ProducedMsg} | R2]) ->
  RefData = #{fetch_vsn => FetchVsn, produce_vsn => ProduceVsn, log_append_time => LAT},
  FetchedMsg = #{ts_type => TType, ts => T, key => K, value => V},
  ok = validate_message_key_val(FetchedMsg, ProducedMsg),
  ok =
    case ?TOPIC_LAT == Topic of
      true -> validate_message_ts_append(RefData, FetchedMsg, ProducedMsg);
      false -> validate_message_ts_create(RefData, FetchedMsg, ProducedMsg)
    end,
  validate_messages(Topic, FetchVsn, R1, R2).

validate_message_key_val(_F = #{key := K, value := V},
                         _P = #{key := K, value := V}) -> ok;
validate_message_key_val(Fetched, Produced) ->
    erlang:error(#{ fetched => Fetched
                  , produced => Produced
                  }).

% Message fetched without timestamp.
validate_message_ts_create(
  #{fetch_vsn := FVsn}, _F = #{ts := undefined, ts_type := undefined}, _P
 ) when FVsn < 2 -> ok;
% Message produced without timestamp.
validate_message_ts_create(
  #{produce_vsn := PVsn}, _F = #{ts := -1, ts_type := create}, _P
 ) when PVsn < 1 -> ok;
% Fetched and produced messages have matching timestamps.
validate_message_ts_create(_RefData, _F = #{ts := T, ts_type := create},
                                     _P = #{ts := T}) -> ok;
% Something unexpected.
validate_message_ts_create(RefData, F, P) ->
    erlang:error(#{ ref_data => RefData
                  , fetched => F
                  , produced => P
                  }).

% Message fetched without timestamp.
validate_message_ts_append(
  #{fetch_vsn := FVsn}, _F = #{ts_type := undefined, ts := undefined}, _P
 ) when FVsn < 2 -> ok;
% Log Append Time not returned during produce, check only that the produced and
% fetched timestamps differ.
validate_message_ts_append(
  #{produce_vsn := PVsn, log_append_time := undefined},
  _F = #{ts := TF, ts_type := append}, _P = #{ts := TP}
 ) when PVsn < 2, TF /= TP -> ok;
% Log Append Time matches the fetched message timestamp and differs from
% the produced message timestamp.
validate_message_ts_append(#{log_append_time := T},
                           _F = #{ts := T, ts_type := append},
                           _P = #{ts := TP}) when T /= TP -> ok;
% Something unexpected.
validate_message_ts_append(RefData, F, P) ->
    erlang:error(#{ ref_data => RefData
                  , fetched => F
                  , produced => P
                  }).

do_fetch(Connection, Topic, Vsn, BeginOffset, MaxBytes) ->
  Req = make_req(Vsn, Topic, BeginOffset, MaxBytes),
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
      do_fetch(Connection, Topic, Vsn, BeginOffset, Size);
    _ ->
      lists:append([Msgs || {_Meta, Msgs} <- Batches])
  end.

with_vsn_topic(Vsn, Topic) ->
  with_connection(
    random_config(),
    Topic,
    fun(Connection) ->
        {BaseOffset, Messages} = produce_randomly(Vsn, Connection, Topic),
        fetch_and_verify(Connection, Topic, Vsn, BaseOffset, Messages)
    end).

produce_randomly(TestVsn, Connection, Topic) ->
  produce_randomly(TestVsn, Connection, Topic, rand_num(?RAND_PRODUCE_BATCH_COUNT), []).

produce_randomly(_TestVsn, _Connection, _Topic, 0, Acc0) ->
  [{BaseOffset, _, _, _} | _] = Acc = lists:reverse(Acc0),
  {BaseOffset, lists:append([lists:map(fun(M) -> {Vsn, LAT, M} end, Msg)
                             || {_, Vsn, LAT, Msg} <- Acc])};
produce_randomly(TestVsn, Connection, Topic, Count, Acc) ->
  {ok, Versions} = kpro:get_api_versions(Connection),
  {MinVsn, MaxVsn} = maps:get(produce, Versions),
  Vsn = case MinVsn =:= MaxVsn of
          true -> MinVsn;
          false -> MinVsn + rand_num(MaxVsn - MinVsn) - 1
        end,
  Opts = rand_produce_opts(Vsn, TestVsn),
  Batch = make_random_batch(rand_num(?RAND_BATCH_SIZE)),
  Req = kpro_req_lib:produce(Vsn, Topic, ?PARTI, Batch, Opts),
  {ok, Rsp0} = kpro:request_sync(Connection, Req, ?TIMEOUT),
  #{ error_code := no_error
   , base_offset := Offset
   } = Rsp = kpro_test_lib:parse_rsp(Rsp0),
  LogAppendTime = maps:get(log_append_time, Rsp, undefined),
  produce_randomly(TestVsn, Connection, Topic, Count - 1, [{Offset, Vsn, LogAppendTime, Batch} | Acc]).

rand_produce_opts(ProduceVsn, FetchVsn) ->
  Common = [no_compression, gzip, snappy],
  #{ compression => rand_element(case ProduceVsn < 2 orelse FetchVsn < 2 of
                                   %% avoid test old api with lz4
                                   %% for more check KIP-57 - Interoperable LZ4 Framing
                                   true -> Common;
                                   false -> [lz4 | Common]
                                 end)
   , required_acks => rand_element([leader_only, all_isr, 1, -1])
   }.

rand_num(N) -> (os:system_time() rem N) + 1.

rand_element(L) -> lists:nth(rand_num(length(L)), L).

make_req(Vsn, Topic, Offset, MaxBytes) ->
  Opts = #{ max_wait_time => 500
          , max_bytes => MaxBytes
          },
  kpro_req_lib:fetch(Vsn, Topic, ?PARTI, Offset, Opts).

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

get_api_vsn_range(Topic) ->
  Config = kpro_test_lib:connection_config(plaintext),
  {ok, Versions} =
    with_connection(Config, Topic, fun(Pid) -> kpro:get_api_versions(Pid) end),
  maps:get(fetch, Versions).

with_connection(Config, Topic, Fun) ->
  ConnFun =
    fun(Endpoints, Cfg) ->
        kpro:connect_partition_leader(Endpoints, Cfg, Topic, ?PARTI)
    end,
  kpro_test_lib:with_connection(Config, ConnFun, Fun).

make_random_batch(Count) ->
  [#{ ts => kpro_lib:now_ts() - rand_num(100)
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
