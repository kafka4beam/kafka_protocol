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
-module(kpro_produce_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro_private.hrl").

-define(PARTI, 0).
-define(TIMEOUT, 5000).

-define(ASSERT_RESPONSE_NO_ERROR(Vsn, Rsp),
        ?assertMatch(#{ partition := ?PARTI
                      , error_code := no_error
                      , base_offset := _
                      }, kpro:parse_response(Rsp))).

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
                 value => make_value(?LINE)
                }
             , #{ts => Ts - 1000,
                 value => make_value(?LINE)
                }
             , #{ts => Ts + 1000,
                 value => make_value(?LINE)
                }
             ],
      Req = kpro_req_lib:produce(Vsn, topic(), ?PARTI, Msgs),
      with_connection(#{ssl => true, sasl => kpro_test_lib:sasl_config(file)},
        fun(Pid) ->
          {ok, Rsp} = kpro:request_sync(Pid, Req, ?TIMEOUT),
          ?ASSERT_RESPONSE_NO_ERROR(Vsn, Rsp)
        end)
  end.

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

% Produce requests since v3 are only allowed to
% contain record batches with magic v2
% magic 0-1 have tuple list as batch input
% magic 2 has map list as batch input
make_batch(Vsn) when Vsn < ?MIN_MAGIC_2_PRODUCE_API_VSN ->
  [ {<<"key1">>, make_value(Vsn)}
  , {<<"key2">>, make_value(Vsn)}
  ];
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
