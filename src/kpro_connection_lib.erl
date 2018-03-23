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
        , query_api_versions/2
        , query_max_version/3
        , with_connection/3
        ]).

-include("kpro_private.hrl").

-type api() :: kpro:api().
-type vsn() :: kpro:vsn().
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
    kpro_connection:close(Connection)
  end.

%% @doc Connect to partition leader.
-spec connect_partition_leader([endpoint()], topic(), partition(),
                               config(), timeout()) ->
        {ok, connection()} | {error, any()}.
connect_partition_leader(BootstrapEndpoints, Topic, Partition,
                         Config, Timeout) ->
  %% Connect without linking to the connection pid
  NolinkConfig = Config#{nolink => true},
  DiscoverLeader =
    fun(Connection) ->
        try
          discover_partition_leader(Connection, Topic, Partition, Timeout)
        after
          kpro_connection:close(Connection)
        end
    end,
  FL =
    [ fun() -> connect_any(BootstrapEndpoints, NolinkConfig) end
    , DiscoverLeader
    , fun(LeaderEndpoint) -> connect_any([LeaderEndpoint], Config) end
    ],
  %% Link the the connection if it's not `nolink => true' in config.
  kpro_lib:ok_pipe(FL, Timeout).

%% @doc Qury API version ranges using the given `kpro_connection' pid.
-spec query_api_versions(connection(), timeout()) ->
        {ok, [{api(), {Min :: vsn(), Max :: vsn()}}]} | {error, any()}.
query_api_versions(Pid, Timeout) ->
  Req = kpro:make_request(api_versions, 0, []),
  case kpro_connection:request_sync(Pid, Req, Timeout) of
    {ok, #kpro_rsp{ api = api_versions
                  , msg = [ {error_code, ErrorCode}
                          , {api_versions, ApiVersions}
                          ]}} ->
      case kpro_error_code:is_error(ErrorCode) of
        true ->
          {error, ErrorCode};
        false ->
          R = [{kpro:find(api_key, Struct),
                {kpro:find(min_version, Struct),
                 kpro:find(max_version, Struct)}} || Struct <- ApiVersions],
          {ok, R}
      end;
    {error, Reason} ->
      {error, Reason}
  end.

%% @doc Qury highest supported version for the given API.
-spec query_max_version(connection(), kpro:api_key(), timeout()) ->
        {ok, kpro:vsn()} | {error, any()}.
query_max_version(Pid, API, Timeout) ->
  case query_api_versions(Pid, Timeout) of
    {ok, Versions} ->
      {_, {_Min, Max}} = lists:keyfind(API, 1, Versions),
      Max;
    {error, Reason} ->
      {error, Reason}
  end.

%%%_* Internal functions =======================================================

connect_any([], _Config, Errors) ->
  {error, lists:reverse(Errors)};
connect_any([{Host, Port} | Rest], Config, Errors) ->
  case kpro_connection:start(Host, Port, Config) of
    {ok, Connection} ->
      {ok, Connection};
    {error, Error} ->
      connect_any(Rest, Config, [{{Host, Port}, Error} | Errors])
  end.

discover_partition_leader(Connection, Topic, Partition, Timeout) ->
  FL =
    [ fun() -> query_max_version(Connection, metadata, Timeout) end
    , fun(Vsn) ->
          Req = kpro:make_request(metadata, Vsn, [Topic]),
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
