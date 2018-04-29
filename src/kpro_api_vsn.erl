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
-export([range/1, kafka_09_range/1]).

-spec range(kpro:api()) -> false | {kpro:vsn(), kpro:vsn()}.
range(offset_commit) -> {2, 2};
range(offset_fetch) -> {1, 2};
range(API) -> kpro_schema:vsn_range(API).

-spec kafka_09_range(kpro:api()) -> false | {kpro:vsn(), kpro:vsn()}.
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

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
