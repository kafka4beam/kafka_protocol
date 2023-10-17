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

%% Supported versions of THIS lib
-module(kpro_api_vsn).
-export([range/1, kafka_09_range/1, intersect/2]).

-export_type([range/0]).

-type range() :: {kpro:vsn(), kpro:vsn()}.

%% @doc Return supported version range of the given API.
%%
%% Majority of the APIs are supported from version 0 up to the
%% latest version when the bnf files are re-generated.
%% With two exceptions.
%%
%% 1. Version 0-1 for offset_commit are not supported:
%%    version 0: Kafka commits offsets to zookeeper
%%    version 1: Thre is a lack of commit retention.
%%
%% 2. offset_fetch version 0 is not supported:
%%    Version 0: Kafka fetches offsets from zookeeper.
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
