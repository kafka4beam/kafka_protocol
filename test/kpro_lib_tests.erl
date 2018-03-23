-module(kpro_lib_tests).
-include_lib("eunit/include/eunit.hrl").
-include("kpro.hrl").

with_timeout_test_() ->
  [ {"ok", ?_assertEqual(ok, kpro_lib:with_timeout(fun() -> ok end, 100))}
  , {"throw",
     ?_assertException(throw, test,
                       kpro_lib:with_timeout(fun() -> throw(test) end, 100))}
  , {"error",
     ?_assertException(error, test,
                       kpro_lib:with_timeout(fun() -> error(test) end, 100))}
  , {"exit",
     ?_assertException(exit, test,
                       kpro_lib:with_timeout(fun() -> exit(test) end, 100))}
  , {"links",
     fun() ->
         Pid = spawn_link(fun() -> receive _ -> ok end end),
         Result = kpro_lib:with_timeout(fun() -> link(Pid) end, 100),
         ?assertEqual(true, Result),
         {links, Links} = process_info(self(), links),
         ?assert(lists:member(Pid, Links))
     end}
  , {"timeout",
     fun() ->
         Parent = self(),
         Result = kpro_lib:with_timeout(
                    fun() ->
                        Parent ! {agent, self()},
                        receive Msg -> exit({unexpected, Msg}) end
                    end, 10),
         Agent = receive {agent, Pid} -> Pid end,
         ?assertEqual({error, timeout}, Result),
         ?assertNot(is_process_alive(Agent))
     end
    }
  ].

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
