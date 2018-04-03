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

-module(kpro_brokers).

-export([ connect_any/2
        , connect_coordinator/3
        , connect_partition_leader/3
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

-define(DEFAULT_TIMEOUT, 5000).

%% @doc Connect to any of the endpoints in the given list.
-spec connect_any([endpoint()], config()) ->
        {ok, connection()} | {error, any()}.
connect_any(Endpoints0, Config) ->
  Endpoints = random_order(Endpoints0),
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

%% @doc Connect partition leader.
%% If the fist arg is not an already established metadata connection
%% but a bootstraping endpoint list, this function will first try to
%% establish a temp connection to any of the bootstraping endpoints.
%% Then send metadata request to discover partition leader broker
%% Finally connect to the leader broker.
-spec connect_partition_leader(connection() | [endpoint()], config(),
                               #{ topic => topic()
                                , partition => partition()
                                , timeout => timeout()
                                }) ->
        {ok, connection()} | {error, any()}.
connect_partition_leader(C, Config, #{ topic := Topic
                                     , partition := Partition
                                     } = Args) when is_pid(C) ->
  Timeout = maps:get(timeout, Args, ?DEFAULT_TIMEOUT),
  FL =
    [ fun() -> discover_partition_leader(C, Topic, Partition, Timeout) end
    , fun(LeaderEndpoint) -> connect_any([LeaderEndpoint], Config) end
    ],
  kpro_lib:ok_pipe(FL, Timeout);
connect_partition_leader(Bootstrap, Config, #{ topic := Topic
                                             , partition := Partition
                                             } = Args) ->
  %% Connect without linking to the connection pid
  NolinkConfig = Config#{nolink => true},
  Timeout = maps:get(timeout, Args, ?DEFAULT_TIMEOUT),
  FL =
    [ fun() -> connect_any(Bootstrap, NolinkConfig) end
    , fun(Connection) ->
        try discover_partition_leader(Connection, Topic, Partition, Timeout)
        after kpro_connection:stop(Connection) end end
    , fun(LeaderEndpoint) -> connect_any([LeaderEndpoint], Config) end
    ],
  kpro_lib:ok_pipe(FL, Timeout).

%% @doc Connect group or transaction coordinator.
%% If the first arg is not a connection pid but a list of bootstraping
%% endpoints, it will frist try to connect to any of the nodes
%% NOTE: 'txn' type only applicable to kafka 0.11 or later
-spec connect_coordinator(connection() | [endpoint()], config(),
                          #{ type => group | txn
                           , id => binary()
                           , timeout => timeout()
                           }) -> {ok, connection()} | {error, any()}.
connect_coordinator(C, Config, #{ type := Type
                                , id := Id
                                } = Args) when is_pid(C) ->
  Timeout = maps:get(timeout, Args, ?DEFAULT_TIMEOUT),
  FL =
    [ fun() -> discover_coordinator(C, Type, Id, Timeout) end
    , fun(CoordinatorEp) -> connect_any([CoordinatorEp], Config) end
    ],
  kpro_lib:ok_pipe(FL, Timeout);
connect_coordinator(Bootstrap, Config, #{ type := Type
                                        , id := Id
                                        } = Args) ->
  Timeout = maps:get(timeout, Args, ?DEFAULT_TIMEOUT),
  NoLinkConfig = Config#{nolink => true},
  FL =
    [ fun() -> connect_any(Bootstrap, NoLinkConfig) end
    , fun(Connection) ->
        try discover_coordinator(Connection, Type, Id, Timeout)
        after kpro_connection:stop(Connection) end end
    , fun(CoordinatorEp) -> connect_any([CoordinatorEp], Config) end
    ],
  kpro_lib:ok_pipe(FL, Timeout).

%% @doc Qury API version ranges using the given `kpro_connection' pid.
-spec get_api_versions(connection()) ->
        {ok, kpro:api_vsn_ranges()} | {error, any()}.
get_api_versions(Connection) ->
  case kpro_connection:get_api_vsns(Connection) of
    {ok, Vsns} ->
      {ok, api_vsn_range_intersection(Vsns)};
    {error, Reason} ->
      {error, Reason}
  end.

%% @doc Qury highest supported version for the given API.
-spec get_max_api_version(connection(), kpro:api_key()) ->
        {ok, kpro:vsn()} | {error, any()}.
get_max_api_version(Connection, API) ->
  case get_api_versions(Connection) of
    {ok, Versions} ->
      {_Min, Max} = maps:get(API, Versions),
      {ok, Max};
    {error, Reason} ->
      {error, Reason}
  end.

%%%_* Internal functions =======================================================

discover_coordinator(Connection, Type, Id, Timeout) ->
  FL =
    [ fun() -> get_max_api_version(Connection, find_coordinator) end
    , fun(0) when Type =:= group ->
          {ok, kpro:make_request(find_coordinator, 0, [{group_id, Id}])};
         (0) when Type =:= txn ->
          {error, {bad_vsn, [{api, find_coordinator}, {type, txn}]}};
         (V) ->
          TypeBin = atom_to_binary(Type, utf8),
          Fields = [ {coordinator_key, Id}, {coordinator_type, TypeBin}],
          {ok, kpro:make_request(find_coordinator, V, Fields)}
      end
    , fun(Req) -> kpro_connection:request_sync(Connection, Req, Timeout) end
    , fun(#kpro_rsp{msg = Rsp}) ->
          ErrorCode = kpro:find(error_code, Rsp),
          ErrMsg = kpro:find(error_message, Rsp, ?kpro_null),
          case kpro_error_code:is_error(ErrorCode) of
            true when ErrMsg =:= ?kpro_null ->
              %% v0
              {error, ErrorCode};
            true ->
              %% v1
              {error, [{error_code, ErrorCode}, {error_msg, ErrMsg}]};
            false ->
              CoorInfo = kpro:find(coordinator, Rsp),
              Host = kpro:find(host, CoorInfo),
              Port = kpro:find(port, CoorInfo),
              {ok, {Host, Port}}
          end
      end
    ],
  kpro_lib:ok_pipe(FL, Timeout).

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

%% Avoid always pounding the first endpoint in bootstraping list.
random_order(L) ->
  RandL = [rand:uniform(1000) || _ <- L],
  RI = lists:sort(lists:zip(RandL, L)),
  [I || {_R, I} <- RI].

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
