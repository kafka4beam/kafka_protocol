-module(kpro_list_offsets_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro.hrl").

-define(TOPIC, <<"test-topic">>).
-define(PARTI, 0).
-define(TIMEOUT, 5000).

list_offsets_test_() ->
  {Min, Max} = query_api_vsn_rage(),
  [ make_test_case(Vsn, Ts) ||
    Vsn <- lists:seq(Min, Max),
    Ts <- ['earliest', 'latest', kpro_lib:now_ts()]
  ].

make_test_case(Vsn, Ts) ->
  {lists:flatten(io_lib:format("vsn = ~p, ts = ~p", [Vsn, Ts])),
  fun() ->
      Req = kpro_req_lib:list_offsets(Vsn, ?TOPIC, ?PARTI, Ts),
      Test = fun(Pid) ->
                 {ok, Rsp} = kpro:request_sync(Pid, Req, ?TIMEOUT),
                 assert_no_error(Rsp)
             end,
      ConnFun = fun(Endpoints, Config) ->
                    kpro:connect_partition_leader(Endpoints, ?TOPIC, ?PARTI,
                                                  Config, 1000)
                end,
      kpro_test_lib:with_connection(ConnFun, Test)
  end}.

assert_no_error(#kpro_rsp{vsn = Vsn, msg = Msg}) ->
  [TopicRsp] = kpro:find(responses, Msg),
  [ {topic, ?TOPIC}
  , {partition_responses, [PartitionRsp]}
  ] = TopicRsp,
  [ {partition, ?PARTI}
  , {error_code, no_error}
  | Rest
  ] = PartitionRsp,
  case Vsn of
    0 -> ?assertMatch([{offsets, [_]}], Rest);
    _ -> ?assertMatch([{timestamp, _}, {offset, _}], Rest)
  end.

query_api_vsn_rage() ->
  F = fun(Pid) -> kpro:query_api_versions(Pid, 1000) end,
  {ok, Versions} = kpro_test_lib:with_connection(F),
  maps:get(list_offsets, Versions).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
