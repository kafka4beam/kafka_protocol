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

offset_commit_range_test() ->
  ?assertEqual({2, 8}, kpro_api_vsn:range(offset_commit)),
  ?assertEqual({2, 2}, kpro_api_vsn:kafka_09_range(offset_commit)).

offset_commit_intersect_test_() ->
  [ ?_assertEqual({2, 8}, kpro_api_vsn:intersect(offset_commit, {0, 8}))
  , ?_assertEqual({2, 7}, kpro_api_vsn:intersect(offset_commit, {2, 7}))
  , ?_assertEqual({4, 8}, kpro_api_vsn:intersect(offset_commit, {4, 9}))
  ].

offset_commit_request_test_() ->
  [ {lists:flatten(io_lib:format("version ~p", [Vsn])),
     fun() -> assert_offset_commit_request(Vsn) end}
    || Vsn <- lists:seq(2, 8)
  ].

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

assert_offset_commit_request(Vsn) ->
  Partition =
    [ {partition_index, 0}
    , {committed_offset, 42}
    , {committed_leader_epoch, -1}
    , {committed_metadata, undefined}
    ],
  Fields =
    [ {group_id, <<"group">>}
    , {generation_id, 1}
    , {member_id, <<"member">>}
    , {group_instance_id, <<"instance">>}
    , {retention_time_ms, -1}
    , {topics,
       [[ {name, <<"topic">>}
        , {partitions, [Partition]}
        ]]}
    ],
  Request = kpro:make_request(offset_commit, Vsn, Fields),
  Encoded = iolist_to_binary(kpro:encode_request(<<"client">>, 1, Request)),
  ?assert(is_binary(Encoded)).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
