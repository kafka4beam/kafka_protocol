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
-module(kpro_schema_tests).

-include_lib("eunit/include/eunit.hrl").

all_test() ->
  lists:foreach(fun test_api/1, kpro_schema:all_apis()).

test_api(API) ->
  ?assertEqual(API, kpro_schema:api_key(kpro_schema:api_key(API))),
  {MinV, MaxV} = kpro_schema:vsn_range(API),
  lists:foreach(fun(V) ->
                    ?assert(is_list(kpro_schema:req(API, V))),
                    ?assert(is_list(kpro_schema:rsp(API, V)))
                end, lists:seq(MinV, MaxV)).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
