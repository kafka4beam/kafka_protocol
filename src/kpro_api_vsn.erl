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
-export([range/1, kafka_09_range/1, intersect/1, intersect/2]).

-export_type([range/0]).

-type range() :: {kpro:vsn(), kpro:vsn()}.
-define(undef, undefined).

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

%% @private Returns the intersection of two version ranges.
%% An error is raised if there is no intersection.
-spec intersect(atom(), false | range(), false | range()) -> false | range().
intersect(_API, Unknown = false, _) -> Unknown;
intersect(API, {Min0, Max0} = Supported, {Min1, Max1} = Received) ->
  {Min2, Max2} = fix_range(API, Min1, Max1),
  Min = max(Min0, Min2),
  Max = min(Max0, Max2),
  case Min > Max of
    true -> erlang:error({no_intersection, Supported, Received});
    false -> {Min, Max}
  end.

%% Special adjustment for received API range.
%% - produce: Minimal version is in fact 3, but Kafka may respond 0.
%% - fetch: Minimal version is in fact 4, but Kafka may respond 0.
fix_range(produce, Min, Max) ->
    case Max >= 8 of
        true ->
            {max(Min, 3), Max};
        false ->
            {Min, Max}
    end;
fix_range(fetch, Min, Max) ->
    case Max >= 11 of
        true ->
            {max(Min, 4), Max};
        false ->
            {Min, Max}
    end;
fix_range(_API, Min, Max) ->
    {Min, Max}.

%% @doc Return the intersection of supported version ranges and received version ranges.
-spec intersect(?undef | list()) -> #{kpro:api() => range()}.
intersect(?undef) ->
  %% kpro_connection is configured not to query api versions (kafka-0.9)
  %% always use minimum supported version in this case
  lists:foldl(
    fun(API, Acc) ->
      case kpro_api_vsn:kafka_09_range(API) of
        false -> Acc;
        {Min, _Max} -> Acc#{API => {Min, Min}}
      end
    end, #{}, kpro_schema:all_apis());
intersect(ReceivedVsns) ->
  maps:fold(
    fun(API, {Min, Max}, Acc) ->
      case intersect(API, {Min, Max}) of
        false -> Acc;
        Intersection -> Acc#{API => Intersection}
      end
    end, #{}, ReceivedVsns).

%% @doc Intersect received api version range with supported range.
-spec intersect(kpro:api(), range()) -> false | range().
intersect(API, Received) ->
  Supported = kpro_api_vsn:range(API),
  try
    intersect(API, Supported, Received)
  catch
    error : {no_intersection, _, _} ->
      Reason = #{reason => incompatible_version_ranges,
                 supported => Supported,
                 received => Received,
                 api => API},
      erlang:error(Reason)
  end.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
