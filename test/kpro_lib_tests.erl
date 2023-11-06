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
         Pid = spawn(fun() -> receive _ -> ok end end),
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

parse_endpoints_test_() ->
  [ {"empty", ?_assertEqual([], parse(""))}
  , {"single", ?_assertEqual([{"127.0.0.1", 1234}], parse("127.0.0.1:1234"))}
  , {"comma", ?_assertEqual([{"h1", 1234}, {"h2", 1235}], parse("h1:1234, h2:1235"))}
  , {"space", ?_assertEqual([{"host1", 1234}, {"host2", 1235}], parse("host1:1234 host2:1235"))}
  , {"plain", ?_assertEqual([{"127.0.0.1", 1234}], parse(plaintext, "plaintext://127.0.0.1:1234"))}
  , {"ssl", ?_assertEqual([{"127.0.0.1", 1234}], parse(ssl, "SSL://127.0.0.1:1234"))}
  , {"sasl_ssl", ?_assertEqual([{"host", 1234}], parse(sasl_ssl, "SASL_ssl://host:1234\n"))}
  , {"sasl_plaintext", ?_assertEqual([{"h", 1234}], parse(sasl_plaintext, "sasl_plaintext://h:1234, "))}
  ].

parse(Endpoints) ->
  kpro_lib:parse_endpoints(undefined, Endpoints).

parse(Proto, Endpoints) ->
  kpro_lib:parse_endpoints(Proto, Endpoints).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
