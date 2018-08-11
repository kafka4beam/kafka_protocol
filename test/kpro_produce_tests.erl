%%%   Copyright (c) 2018, Klarna Bank AB (publ)
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
-module(kpro_produce_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro_private.hrl").

-define(PARTI, 0).
-define(TIMEOUT, 5000).

-define(ASSERT_RESPONSE_NO_ERROR(Vsn, Rsp),
        ?assertMatch(#{ partition := ?PARTI
                      , error_code := no_error
                      , base_offset := _
                      }, kpro_test_lib:parse_rsp(Rsp))).

magic_v0_basic_test_() ->
  {Min, Max} = get_api_vsn_range(),
  MkTestFun =
    fun(Vsn) ->
        fun() ->
          with_connection(
            fun(Pid) ->
              Req = make_req(Vsn),
              {ok, Rsp} = kpro:request_sync(Pid, Req, ?TIMEOUT),
              ?ASSERT_RESPONSE_NO_ERROR(Vsn, Rsp)
            end)
        end
    end,
  MkTest =
    fun(Vsn) ->
        {"batch magic version 0 in produce request version " ++
         integer_to_list(Vsn), MkTestFun(Vsn)}
    end,
  [MkTest(Vsn) || Vsn <- lists:seq(Min, Max)].

%% Timestamp within batch may not have to be monotonic.
non_monotoic_ts_in_batch_test() ->
  {_, Vsn} = get_api_vsn_range(),
  case Vsn < ?MIN_MAGIC_2_PRODUCE_API_VSN of
    true ->
      %% Nothing to test for kafka < 0.11
      ok;
    false ->
      Ts = kpro_lib:now_ts() - 1000,
      Msgs = [ #{ts => Ts,
                 value => make_value(?LINE),
                 headers => [{<<"foo">>, <<"bar">>}]
                }
             , #{ts => Ts - 1000,
                 value => make_value(?LINE),
                 headers => [{<<"foo">>, <<"bar">>},
                             {<<"baz">>, <<"gazonga">>}]
                }
             , #{ts => Ts + 1000,
                 value => make_value(?LINE),
                 headers => []
                }
             ],
      Req = kpro_req_lib:produce(Vsn, topic(), ?PARTI, Msgs),
      with_connection(#{ssl => true, sasl => kpro_test_lib:sasl_config(plain)},
        fun(Pid) ->
          {ok, Rsp} = kpro:request_sync(Pid, Req, ?TIMEOUT),
          ?ASSERT_RESPONSE_NO_ERROR(Vsn, Rsp)
        end)
  end.

%% batches can be encoded by caller before making a produce request
encode_batch_beforehand_test() ->
  {_, Vsn} = get_api_vsn_range(),
  Batch = [#{ts => kpro_lib:now_ts(),
             value => make_value(?LINE),
             headers => []}],
  Magic = kpro_lib:produce_api_vsn_to_magic_vsn(Vsn),
  Bin = kpro:encode_batch(Magic, Batch, no_compression),
  Req = kpro_req_lib:produce(Vsn, topic(), ?PARTI, Bin),
  with_connection(
    fun(Pid) ->
        {ok, Rsp} = kpro:request_sync(Pid, Req, ?TIMEOUT),
        ?ASSERT_RESPONSE_NO_ERROR(Vsn, Rsp)
    end).

%% async send test
async_send_test() ->
  {_, Vsn} = get_api_vsn_range(),
  Batch1 = [#{ts => kpro_lib:now_ts(), value => make_value(?LINE)}],
  Batch2 = [#{ts => kpro_lib:now_ts(), value => make_value(?LINE)}],
  Req1 = kpro_req_lib:produce(Vsn, topic(), ?PARTI, Batch1),
  Req2 = kpro_req_lib:produce(Vsn, topic(), ?PARTI, Batch2),
  with_connection(
    fun(Pid) ->
        ok = kpro:send(Pid, Req1),
        ok = kpro:request_async(Pid, Req2),
        Assert = fun(Req, Rsp) ->
                     ?ASSERT_RESPONSE_NO_ERROR(Vsn, Rsp),
                     ?assertEqual(Req#kpro_req.ref, Rsp#kpro_rsp.ref)
                 end,
        receive {msg, Pid, Rsp1} -> Assert(Req1, Rsp1) end,
        receive {msg, Pid, Rsp2} -> Assert(Req2, Rsp2) end,
        receive Msg -> erlang:throw({unexpected, Msg}) after 10 -> ok end
    end).

make_req(Vsn) ->
  Batch = make_batch(Vsn),
  kpro_req_lib:produce(Vsn, topic(), ?PARTI, Batch).

get_api_vsn_range() ->
  {ok, Versions} = with_connection(fun(Pid) -> kpro:get_api_versions(Pid) end),
  maps:get(produce, Versions).

with_connection(Fun) ->
  kpro_test_lib:with_connection(Fun).

with_connection(Config, Fun) ->
  ConnFun =
    fun(Endpoints, Cfg) ->
        kpro:connect_partition_leader(Endpoints, Cfg, topic(), ?PARTI)
    end,
  kpro_test_lib:with_connection(Config, ConnFun, Fun).

make_batch(Vsn) ->
  F = fun(I) ->
          #{ key => iolist_to_binary("key" ++ integer_to_list(I))
           , value => make_value(Vsn)
           }
      end,
  [F(1), F(2)].

make_value(Random) ->
  term_to_binary({Random, os:system_time()}).

topic() -> kpro_test_lib:get_topic().

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
