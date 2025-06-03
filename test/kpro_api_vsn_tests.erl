%%%   Copyright (c) 2025, Kafka4beam contributors
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
-module(kpro_api_vsn_tests).

-include_lib("eunit/include/eunit.hrl").

intersect_test_() ->
  API = offset_commit,
  Received = {0, 0},
  [?_assertError(#{api := API,
                   reason := incompatible_version_ranges,
                   supported := _,
                   received := Received},
                 kpro_api_vsn:intersect(API, Received)),
   ?_assertEqual(false, kpro_api_vsn:intersect(unknown, {0, 1})),
   ?_assertEqual(#{}, kpro_api_vsn:intersect(#{unknown => {0, 1}}))
  ].

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
