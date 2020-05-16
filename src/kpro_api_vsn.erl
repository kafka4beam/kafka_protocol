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

%% Supported versions of THIS lib
-module(kpro_api_vsn).
-export([range/1, kafka_09_range/1, intersect/2]).

-export_type([range/0]).

-type range() :: {kpro:vsn(), kpro:vsn()}.

-spec range(kpro:api()) -> false | range().
range(offset_commit) -> {2, 2};
range(offset_fetch) -> {1, 2};
range(API) -> kpro_schema:vsn_range(API).

-spec kafka_09_range(kpro:api()) -> false | range().
kafka_09_range(produce) -> {0, 0};
kafka_09_range(fetch) -> {0, 0};
kafka_09_range(list_offsets) -> {0, 0};
kafka_09_range(metadata) -> {0, 0};
kafka_09_range(offset_commit) -> {2, 2};
kafka_09_range(offset_fetch) -> {1, 1};
kafka_09_range(find_coordinator) -> {0, 0};
kafka_09_range(join_group) -> {0, 0};
kafka_09_range(heartbeat) -> {0, 0};
kafka_09_range(leave_group) -> {0, 0};
kafka_09_range(sync_group) -> {0, 0};
kafka_09_range(describe_groups) -> {0, 0};
kafka_09_range(list_groups) -> {0, 0};
kafka_09_range(_) -> false.

%% @doc Returns the intersection of two version ranges.
%% An error is raised if there is no intersection.
-spec intersect(false | range(), false | range()) -> false | range().
intersect(false, _) -> false;
intersect(_, false) -> false;
intersect({Min1, Max1} = R1, {Min2, Max2} = R2) ->
  Min = max(Min1, Min2),
  Max = min(Max1, Max2),
  case Min > Max of
    true -> erlang:error({no_intersection, R1, R2});
    false -> {Min, Max}
  end.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
