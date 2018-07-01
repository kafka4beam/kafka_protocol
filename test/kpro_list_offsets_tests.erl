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
-module(kpro_list_offsets_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro.hrl").

-define(TOPIC, <<"test-topic">>).
-define(PARTI, 0).
-define(TIMEOUT, 5000).

list_offsets_test_() ->
  {Min, Max} = get_api_vsn_rage(),
  [ make_test_case(Vsn, Ts) ||
    Vsn <- lists:seq(Min, Max),
    Ts <- [earliest, latest, kpro_lib:now_ts()]
  ].

make_test_case(Vsn, Ts) ->
  {lists:flatten(io_lib:format("vsn = ~p, ts = ~p", [Vsn, Ts])),
  fun() ->
      Req = kpro_req_lib:list_offsets(Vsn, ?TOPIC, ?PARTI, Ts),
      Test = fun(Pid) ->
                 {ok, Rsp} = kpro:request_sync(Pid, Req, ?TIMEOUT),
                 assert_no_error(kpro_test_lib:parse_rsp(Rsp))
             end,
      ConnFun =
        fun(Endpoints, Config) ->
            kpro:connect_partition_leader(Endpoints, Config, ?TOPIC, ?PARTI)
        end,
      kpro_test_lib:with_connection(ConnFun, Test)
  end}.

assert_no_error(Rsp) ->
  ?assertMatch(#{ error_code := no_error
                , offset := _
                }, Rsp).

get_api_vsn_rage() ->
  F = fun(Pid) -> kpro:get_api_versions(Pid) end,
  {ok, Versions} = kpro_test_lib:with_connection(F),
  maps:get(list_offsets, Versions).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
