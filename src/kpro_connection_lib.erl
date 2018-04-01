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

-module(kpro_connection_lib).

-export([ connect_any/2
        , connect_partition_leader/5
        , get_api_versions/1
        , get_max_api_version/2
        , with_connection/3
        ]).

-include("kpro_private.hrl").

-type endpoint() :: kpro:endpoint().
-type topic() :: kpro:topic().
-type partition() :: kpro:partition().
-type config() :: kpro_connection:config().
-type connection() :: kpro_connection:connection().

%% @doc Connect to any of the endpoints in the given list.
-spec connect_any([endpoint()], config()) ->
        {ok, connection()} | {error, any()}.
connect_any(Endpoints, Config) ->
  connect_any(Endpoints, Config, []).

%% @doc Evaluate give function with a connection to any of the nodes in
%% in the given endpoints.
%% Raise a 'throw' exception if failed to connect all endpoints.
-spec with_connection([endpoint()], config(),
                      fun((connection()) -> Return)) ->
        Return when Return :: term().
with_connection(Endpoints, Config, Fun) ->
  %% connect to any bootstrap endpoint (without linking to self)
  Connection =
    case connect_any(Endpoints, Config#{nolink => true}) of
      {ok, Pid} -> Pid;
      {error, Reasons} -> erlang:throw({failed_to_connect, Reasons})
    end,
  try
    Fun(Connection)
  after
    kpro_connection:stop(Connection)
  end.

%% @doc Connect to partition leader.
-spec connect_partition_leader([endpoint()], config(),
                               topic(), partition(), timeout()) ->
        {ok, connection()} | {error, any()}.
connect_partition_leader(BootstrapEndpoints, Config,
                         Topic, Partition, Timeout) ->
  %% Connect without linking to the connection pid
  NolinkConfig = Config#{nolink => true},
  DiscoverLeader =
    fun(Connection) ->
        try
          discover_partition_leader(Connection, Topic, Partition, Timeout)
        after
          kpro_connection:stop(Connection)
        end
    end,
  FL =
    [ fun() -> connect_any(BootstrapEndpoints, NolinkConfig) end
    , DiscoverLeader
    , fun(LeaderEndpoint) -> connect_any([LeaderEndpoint], Config) end
    ],
  kpro_lib:ok_pipe(FL, Timeout).

%% @doc Qury API version ranges using the given `kpro_connection' pid.
-spec get_api_versions(connection()) ->
        {ok, kpro:api_vsn_ranges()} | {error, any()}.
get_api_versions(Pid) ->
  case kpro_connection:get_api_vsns(Pid) of
    {ok, Vsns} ->
      {ok, api_vsn_range_intersection(Vsns)};
    {error, Reason} ->
      {error, Reason}
  end.

%% @doc Qury highest supported version for the given API.
-spec get_max_api_version(connection(), kpro:api_key()) ->
        {ok, kpro:vsn()} | {error, any()}.
get_max_api_version(Pid, API) ->
  case get_api_versions(Pid) of
    {ok, Versions} ->
      {_Min, Max} = maps:get(API, Versions),
      {ok, Max};
    {error, Reason} ->
      {error, Reason}
  end.

%%%_* Internal functions =======================================================

api_vsn_range_intersection(undefined) ->
  %% kpro_connection is configured not to query api versions (kafka-0.9)
  %% always use minimum supported version in this case
  lists:foldl(
    fun(API, Acc) ->
        try kpro_api_vsn:kafka_09_range(API) of
          {Min, _Max} ->
            Acc#{API => {Min, Min}}
        catch
          error : function_clause ->
            Acc
        end
    end, #{}, kpro_schema:all_apis());
api_vsn_range_intersection(Vsns) ->
  maps:fold(
    fun(API, {Min, Max}, Acc) ->
        case api_vsn_range_intersection(API, Min, Max) of
          false -> Acc;
          Intersection -> Acc#{API => Intersection}
        end
    end, #{}, Vsns).

%% Intersect received api version range with supported range.
api_vsn_range_intersection(API, MinReceived, MaxReceived) ->
  Supported = try
                kpro_api_vsn:range(API)
              catch
                error : function_clause ->
                  false
              end,
  case Supported of
    {MinSupported, MaxSupported} ->
      Min = max(MinSupported, MinReceived),
      Max = min(MaxSupported, MaxReceived),
      Min =< Max andalso {Min, Max};
    false ->
      false
  end.

connect_any([], _Config, Errors) ->
  {error, lists:reverse(Errors)};
connect_any([{Host, Port} | Rest], Config, Errors) ->
  case kpro_connection:start(Host, Port, Config) of
    {ok, Connection} ->
      {ok, Connection};
    {error, Error} ->
      connect_any(Rest, Config, [{{Host, Port}, Error} | Errors])
  end.

%% Can not get dialyzer working for this call: kpro_req_lib:metadata(Vsn, [Topic])
-dialyzer([{nowarn_function, [discover_partition_leader/4]}]).
-spec discover_partition_leader(connection(), topic(), partition(), timeout()) ->
        {ok, endpoint()} | {error, any()}.
discover_partition_leader(Connection, Topic, Partition, Timeout) ->
  FL =
    [ fun() -> get_max_api_version(Connection, metadata) end
    , fun(Vsn) ->
          Req = kpro_req_lib:metadata(Vsn, [Topic]),
          kpro_connection:request_sync(Connection, Req, Timeout)
      end
    , fun(#kpro_rsp{msg = Meta}) ->
          Brokers = kpro:find(brokers, Meta),
          [TopicMeta] = kpro:find(topic_metadata, Meta),
          ErrorCode = kpro:find(error_code, TopicMeta),
          case kpro_error_code:is_error(ErrorCode) of
            true ->
              {error, ErrorCode};
            false ->
              {ok, {Brokers, TopicMeta}}
          end
      end
    , fun({Brokers, TopicMeta}) ->
          Partitions = kpro:find(partition_metadata, TopicMeta),
          Pred = fun(P_Meta) -> kpro:find(partition, P_Meta) =:= Partition end,
          case lists:filter(Pred, Partitions) of
            [] ->
              %% Partition number is out of range
              {error, ?EC_UNKNOWN_TOPIC_OR_PARTITION};
            [PartitionMeta] ->
              {ok, {Brokers, PartitionMeta}}
          end
      end
    , fun({Brokers, PartitionMeta}) ->
          ErrorCode = kpro:find(error_code, PartitionMeta),
          case kpro_error_code:is_error(ErrorCode) of
            true -> {error, ErrorCode};
            false -> {ok, {Brokers, PartitionMeta}}
          end
      end
    , fun({Brokers, PartitionMeta}) ->
          LeaderBrokerId = kpro:find(leader, PartitionMeta),
          Pred = fun(BrokerMeta) ->
                     kpro:find(node_id, BrokerMeta) =:= LeaderBrokerId
                 end,
          [Broker] = lists:filter(Pred, Brokers),
          Host = kpro:find(host, Broker),
          Port = kpro:find(port, Broker),
          {ok, {Host, Port}}
      end
    ],
  kpro_lib:ok_pipe(FL).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
