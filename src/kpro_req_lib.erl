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

%% Help functions to make requests

-module(kpro_req_lib).

-export([ list_offsets/4
        , list_offsets/5
        , list_offsets/6
        ]).

-export([ fetch/5
        ]).

-export([ produce/4
        , produce/5
        ]).

-export([ metadata/2
        , metadata/3
        ]).

-export([ add_offsets_to_txn/2
        , add_partitions_to_txn/2
        , end_txn/2
        , txn_offset_commit/4
        ]).

-export([ create_partitions/3
        , create_topics/3
        , delete_topics/3
        ]).

-export([ describe_configs/3
        , alter_configs/3
        ]).

-export([ encode/3
        , make/3
        ]).

-export_type([ fetch_opts/0
             ]).

-include("kpro_private.hrl").
-define(DEFAULT_ACK_TIMEOUT, 10000).
-define(FIELD_ENCODE_ERROR(Reason, EncoderStack),
        {field_encode_error, Reason, EncoderStack}).
-define(IS_NON_EMPTY_KV_LIST(L), (is_list(L) andalso L =/= [] andalso is_tuple(hd(L)))).
-define(IS_STRUCT_DATA(S), (is_map(S) orelse ?IS_NON_EMPTY_KV_LIST(S))).
-define(IS_STRUCT_SCHEMA(S), (is_list(S) orelse is_map(S))).

-type vsn() :: kpro:vsn().
-type topic() :: kpro:topic().
-type req() :: kpro:req().
-type msg_ts() :: kpro:msg_ts().
-type isolation_level() :: kpro:isolation_level().
-type count() :: kpro:count().
-type batch_input() :: kpro:batch_input().
-type produce_opts() :: kpro:produce_opts().
-type txn_ctx() :: kpro:txn_ctx().
-type client_id() :: kpro:client_id().
-type corr_id() :: kpro:corr_id().
-type api() :: kpro:api().
-type struct() :: kpro:struct().
-type offset() :: kpro:offset().
-type wait() :: kpro:wait().
-type partition() :: kpro:partition().
-type group_id() :: kpro:group_id().
-type offsets_to_commit() :: kpro:offsets_to_commit().
-type fetch_opts() :: #{ max_wait_time => wait()
                       , min_bytes => count()
                       , max_bytes => count()
                       , isolation_level => isolation_level()
                       , session_id => kpro:int32()
                       , session_epoch => kpro:int32()
                       , rack_id => iodata()
                       }.
%% Options for a `fetch' request.
%%
%% It is a map with following keys (all of them are optional):
%% <ul>
%%  <li>`max_wait_time': The maximum time (in millis) to block wait until there are
%%       enough messages that have in sum at least `min_bytes' bytes.
%%       The waiting will end as soon as either `min_bytes' is satisfied or
%%       `max_wait_time' is exceeded, whichever comes first. Defaults to 1 second.</li>
%%  <li>`min_bytes': The minimum size of the message set. If it there are not enough
%%       messages, Kafka will block wait (but at most for `max_wait_time').
%%       This implies that the response may be actually smaller in case the time
%%       runs out. If you set it to 0, Kafka will respond immediately (possibly
%%       with an empty message set). You can use this option together with
%%       `max_wait_time' to configure throughput, latency, and size of message sets.
%%       Defaults to 0.</li>
%%  <li>`max_bytes': The maximum size of the message set. Note that this is not an
%%       absolute maximum, if the first message in the message set is larger than
%%       this value, the message will still be returned to ensure that progress can
%%       be made. Defaults to 1 MB.</li>
%%  <li>`isolation_level': This setting controls the visibility of transactional
%%       records. Using `read_uncommitted' makes all records visible.
%%       With `read_committed', non-transactional and committed transactional records
%%       are visible. To be more concrete, `read_committed' returns all data from
%%       offsets smaller than the current LSO (last stable offset), and enables the
%%       inclusion of the list of aborted transactions in the result, which allows
%%       consumers to discard aborted transactional records. Defaults to `read_committed'.
%%       </li>
%%  <li>`session_id': Fetch session ID. This can be useful when the fetch request
%%       spans over multiple topic-partitions. However, fetch requests in `kpro' can
%%       span only over a single topic-partition and so `kpro' by default does not use
%%       fetch sessions (by setting appropriate `session_id' and `session_epoch' default
%%       values). Defaults to 0.</li>
%%  <li>`session_epoch': Fetch session epoch. Holds the same as above. Defaults to -1.</li>
%%  <li>`rack_id': The consumer's rack ID. This allow consumers fetching from closest
%%       replica (instead the leader). Defaults to `undefined'.</li>
%% </ul>

%% @doc Make a `metadata' request
-spec metadata(vsn(), all | [topic()]) -> req().
metadata(Vsn, Topics) ->
  metadata(Vsn, Topics, _IsAutoCreateAllowed = false).

%% @doc Make a `metadata' request
-spec metadata(vsn(), all | [topic()], boolean()) -> req().
metadata(Vsn, [], IsAutoCreateAllowed) ->
  metadata(Vsn, all, IsAutoCreateAllowed);
metadata(Vsn, Topics, IsAutoCreateAllowed) ->
  make(metadata, Vsn,
       #{topics => metadata_topics_list(Vsn, Topics),
         allow_auto_topic_creation => IsAutoCreateAllowed,
         include_cluster_authorized_operations => false,
         include_topic_authorized_operations => false,
         tagged_fields => #{}
        }).

%% version 0 expects an empty array for 'all'
%% all later versions expect 'null' for 'all'
metadata_topics_list(0, all) -> [];
metadata_topics_list(_, all) -> ?kpro_null;
metadata_topics_list(_, Names) ->
  [#{name => Name, tagged_fields => #{}} || Name <- Names].

%% @doc Help function to construct a `list_offset' request
%% against one single topic-partition.
-spec list_offsets(vsn(), topic(), partition(), msg_ts()) -> req().
list_offsets(Vsn, Topic, Partition, Time) ->
  list_offsets(Vsn, Topic, Partition, Time, ?kpro_read_committed).

%% @doc Help function to construct a `list_offset' request against one single
%% topic-partition. In transactional mode,
%% set `IsolationLevel = ?kpro_read_uncommitted' to list uncommitted offsets.
-spec list_offsets(vsn(), topic(), partition(),
                   latest | earliest | msg_ts(),
                   isolation_level()) -> req().
list_offsets(Vsn, Topic, Partition, Time, IsolationLevel) ->
  list_offsets(Vsn, Topic, Partition, Time,
               IsolationLevel, _LeaderEpoch = -1).

%% @doc Extends `list_offsets/5' with leader-epoch number which can be obtained
%% from metadata response for each partition.
-spec list_offsets(vsn(), topic(), partition(),
                   latest | earliest | msg_ts(),
                   isolation_level(),
                   kpro:leader_epoch()) -> req().
list_offsets(Vsn, Topic, Partition, Time0, IsolationLevel, LeaderEpoch) ->
  Time = offset_time(Time0),
  PartitionFields =
    case Vsn of
      0 ->
        [{partition, Partition},
         {timestamp, Time},
         {max_num_offsets, 1}];
      _ ->
        %% max_num_offsets is removed since version 1
        [{partition, Partition},
         {timestamp, Time},
         {current_leader_epoch, LeaderEpoch}
        ]
    end,
  Fields =
    [{replica_id, ?KPRO_REPLICA_ID},
     {isolation_level, IsolationLevel},
     {topics, [ [{topic, Topic},
                 {partitions, [ PartitionFields ]}]
              ]}
    ],
  make(list_offsets, Vsn, Fields).

%% @doc Help function to construct a `fetch' request
%% against one single topic-partition. In transactional mode, set
%% `IsolationLevel = kpro_read_uncommitted' to fetch uncommitted messages.
-spec fetch(vsn(), topic(), partition(), offset(), fetch_opts()) -> req().
fetch(Vsn, Topic, Partition, Offset, Opts) ->
  MaxWaitTime = maps:get(max_wait_time, Opts, timer:seconds(1)),
  MinBytes = maps:get(min_bytes, Opts, 0),
  MaxBytes = maps:get(max_bytes, Opts, 1 bsl 20), %% 1M
  IsolationLevel = maps:get(isolation_level, Opts, ?kpro_read_committed),
  %% See: https://cwiki.apache.org/confluence/display/KAFKA/KIP-227%3A+Introduce+Incremental+FetchRequests+to+Increase+Partition+Scalability
  %% Consumer session is useful when fetch request spans across multiple
  %% topic-partitions, so that:
  %% 1. The consumer may fetch from only a subset of the topic-partitions
  %%    in case e.g. avoid immediately fetch again from partitions which
  %%    have messages recently received.
  %% 2. The broker do not have to send a topic/partition response at all
  %%    if there is not any new messages appended or no metadata change
  %%    sice the last fetch response.
  %%    i.e. Send only changed data.
  %% The default values are to disable fetch session.
  SessionID = maps:get(session_id, Opts, 0),
  Epoch = maps:get(session_epoch, Opts, -1),
  %% Leader epoch is returned from topic-partition metadata.
  %% kafka partition leader make use of this number to fence consumers with
  %% stale metadata.
  LeaderEpoch = maps:get(leader_epoch, Opts, -1),
  %% Rack ID is to allow consumers fetching from closet replica (instead the leader)
  RackID = maps:get(rack_id, Opts, ?kpro_null),
  Fields =
    [{replica_id, ?KPRO_REPLICA_ID},
     {max_wait_time, MaxWaitTime},
     {max_bytes, MaxBytes},
     {min_bytes, MinBytes},
     {isolation_level, IsolationLevel},
     {session_id, SessionID},
     {session_epoch, Epoch},
     {topics,[[{topic, Topic},
               {partitions,
                [[{partition, Partition},
                  {fetch_offset, Offset},
                  {partition_max_bytes, MaxBytes},
                  {log_start_offset, -1}, %% irelevant to clients
                  {current_leader_epoch, LeaderEpoch}
                 ]]}]]},
     % we always fetch from one single topic-partition
     % never need to forget any
     {forgotten_topics_data, []},
     {rack_id, RackID}
    ],
  make(fetch, Vsn, Fields).

%% @doc Help function to construct a produce request.
produce(Vsn, Topic, Partition, Batch) ->
  produce(Vsn, Topic, Partition, Batch, #{}).

%% @doc Help function to construct a produce request.
%% By default, it constructs a non-transactional produce request.
%% For transactional produce requests, below conditions should be met.
%% 1. `Batch' arg must be be a `[map()]' to indicate magic v2,
%%     for example: `[#{key => Key, value => Value, ts => Ts}]'.
%%     Current system time will be taken if `ts' is missing in batch input.
%%     It may also be `binary()' if user choose to encode a batch beforehand.
%%     This could be helpful when a large batch can be encoded in another
%%     process, so it may pass large binary instead of list between processes.
%% 2. `first_sequence' must exist in `Opts'.
%%     It should be the sequence number for the fist message in batch.
%%     Maintained by producer, sequence numbers should start from zero and be
%%     monotonically increasing, with one sequence number per topic-partition.
%% 3. `txn_ctx' (which is of spec `kpro:txn_ctx()') must exist in `Opts'
-spec produce(vsn(), topic(), partition(),
              binary() | batch_input(), produce_opts()) -> req().
produce(Vsn, Topic, Partition, Batch, Opts) ->
  ok = assert_known_api_and_vsn(produce, Vsn),
  RequiredAcks = required_acks(maps:get(required_acks, Opts, all_isr)),
  Compression = maps:get(compression, Opts, ?no_compression),
  AckTimeout = maps:get(ack_timeout, Opts, ?DEFAULT_ACK_TIMEOUT),
  TxnCtx = maps:get(txn_ctx, Opts, false),
  FirstSequence = maps:get(first_sequence, Opts, -1),
  MagicV = kpro_lib:produce_api_vsn_to_magic_vsn(Vsn),
  EncodedBatch =
    case is_binary(Batch) of
      true ->
        %% already encoded non-transactional batch
        Batch;
      false when TxnCtx =:= false ->
        %% non-transactional batch
        kpro_batch:encode(MagicV, Batch, Compression);
      false ->
        %% transactional batch
        true = FirstSequence >= 0, %% assert
        kpro_batch:encode_tx(Batch, Compression, FirstSequence, TxnCtx)
    end,
  Msg =
    [ [encode(string, transactional_id(TxnCtx)) || Vsn > 2]
    , encode(int16, RequiredAcks)
    , encode(int32, AckTimeout)
    , encode(int32, 1) %% topic array header
    , encode(string, Topic)
    , encode(int32, 1) %% partition array header
    , encode(int32, Partition)
    , encode(bytes, EncodedBatch)
    ],
  #kpro_req{ api = produce
           , vsn = Vsn
           , msg = Msg
           , ref = make_ref()
           , no_ack = RequiredAcks =:= 0
           }.

%% @doc Make `end_txn' request.
-spec end_txn(txn_ctx(), commit | abort) -> req().
end_txn(TxnCtx, CommitOrAbort) ->
  Result = case CommitOrAbort of
             commit -> true;
             abort -> false
           end,
  Body = TxnCtx#{transaction_result => Result},
  make(end_txn, _Vsn = 0, Body).

%% @doc Make `add_partitions_to_txn' request.
-spec add_partitions_to_txn(txn_ctx(), [{topic(), partition()}]) -> req().
add_partitions_to_txn(TxnCtx, TopicPartitionList) ->
  Grouped =
    lists:foldl(
      fun({Topic, Partition}, Acc) ->
          kpro_lib:update_map(
            Topic, fun(PL) -> [Partition | PL] end,
            [Partition], Acc)
      end, #{}, TopicPartitionList),
  Body = TxnCtx#{topics => tp_map_to_array(topic, Grouped)},
  make(add_partitions_to_txn, _Vsn = 0, Body).

%% @doc Make a `txn_offset_commit' request.
-spec txn_offset_commit(group_id(), txn_ctx(),
                        offsets_to_commit(), binary()) -> req().
txn_offset_commit(GrpId, TxnCtx, Offsets, UserData) when is_map(Offsets) ->
  txn_offset_commit(GrpId, TxnCtx, maps:to_list(Offsets), UserData);
txn_offset_commit(GrpId, TxnCtx, Offsets, DefaultUserData) ->
  All =
    lists:foldl(
      fun({{Topic, Partition}, OffsetUd}, Acc) ->
          {Offset, UserData} =
            case OffsetUd of
              {O, D} -> {O, D};
              O      -> {O, DefaultUserData}
            end,
          PD = #{ partition_index => Partition
                , committed_offset => Offset
                , committed_leader_epoch => -1
                , committed_metadata => UserData
                },
          kpro_lib:update_map(Topic, fun(PDL) -> [PD | PDL] end, [PD], Acc)
      end, #{}, Offsets),
  Body = TxnCtx#{topics => tp_map_to_array(name, All), group_id => GrpId},
  make(txn_offset_commit, _Vsn = 0, Body).

%% @doc Make `add_offsets_to_txn' request.
-spec add_offsets_to_txn(txn_ctx(), group_id()) -> req().
add_offsets_to_txn(TxnCtx, CgId) ->
  Body = TxnCtx#{group_id => CgId},
  make(add_offsets_to_txn, _Vsn = 0, Body).

%% @doc Make `create_topics' request.
%% if 0 is given as `timeout' option the request will trigger a creation
%% but return immediately.
%% `validate_only' option is only relevant when the API version is
%% greater than 0.
-spec create_topics(vsn(), [Topics :: kpro:struct()],
                    #{timeout => kpro:int32(),
                      validate_only => boolean()}) -> req().
create_topics(Vsn, Topics, Opts) ->
  Timeout = maps:get(timeout, Opts, 0),
  ValidateOnly = maps:get(validate_only, Opts, false),
  Body = #{ topics => Topics
          , timeout_ms => Timeout
          , validate_only => ValidateOnly
          },
  make(create_topics, Vsn, Body).

%% @doc Make a `create_partitions' request.
-spec create_partitions(vsn(), [Topics :: kpro:struct()],
                        #{timeout => kpro:int32(),
                          validate_only => boolean()}) -> req().
create_partitions(Vsn, Topics, Opts) ->
  Timeout = maps:get(timeout, Opts, 0),
  ValidateOnly = maps:get(validate_only, Opts, false),
  Body = #{ topic_partitions => Topics
          , timeout => Timeout
          , validate_only => ValidateOnly
          },
  make(create_partitions, Vsn, Body).

%% @doc Make `delete_topics' request.
-spec delete_topics(vsn(), [topic()], #{timeout => kpro:int32()}) -> req().
delete_topics(Vsn, Topics, Opts) ->
  Timeout = maps:get(timeout, Opts, 0),
  Body = #{ topic_names => Topics
          , timeout_ms => Timeout
          },
  make(delete_topics, Vsn, Body).

%% @doc Make a `describe_configs' request.
%% `include_synonyms' option is only relevant when the API version is
%% greater than 0.
-spec describe_configs(vsn(), [Resources :: kpro:struct()],
                       #{include_synonyms => boolean()}) -> req().
describe_configs(Vsn, Resources, Opts) ->
  IncludeSynonyms = maps:get(include_synonyms, Opts, false),
  Body = #{ resources => Resources
          , include_synonyms => IncludeSynonyms
          },
  make(describe_configs, Vsn, Body).

%% @doc Make an `alter_configs' request.
-spec alter_configs(vsn(), [Resources :: kpro:struct()],
                    #{validate_only => boolean()}) -> req().
alter_configs(Vsn, Resources, Opts) ->
  ValidateOnly = maps:get(validate_only, Opts, false),
  Body = #{ resources => Resources
          , validate_only => ValidateOnly
          },
  make(alter_configs, Vsn, Body).

%% @doc Help function to make a request body.
-spec make(api(), vsn(), struct()) -> req().
make(API, Vsn, Fields) ->
  ok = assert_known_api_and_vsn(API, Vsn),
  #kpro_req{ api = API
           , vsn = Vsn
           , msg = encode_struct(API, Vsn, Fields)
           , ref = make_ref()
           }.

%% @doc Encode a request to bytes that can be sent on wire.
-spec encode(client_id(), corr_id(), req()) -> iodata().
encode(ClientName, CorrId, Req) ->
  #kpro_req{api = API, vsn = Vsn, msg = Msg} = Req,
  ApiKey = kpro_schema:api_key(API),
  % There are 3 versions of request headers.
  % (but the header itself has no version number indicator).
  % Version 0 was never supported in this library.
  % Version 1 added the client-name string field
  % Version 2 added the flexible tagged fields (which is always null so far)
  Header =
    [ encode(int16, ApiKey)
    , encode(int16, Vsn)
    , encode(int32, CorrId)
    , encode(string, ClientName)
    | case Vsn >= kpro_schema:min_flexible_vsn(API) of
        true  -> [0]; %% NULL for tagged fields in request header (version 2)
        false -> [] %% request header version 1
      end
    ],
  [Header | encode_struct(API, Vsn, Msg)].

%%%_* Internal functions =======================================================

%% Turn #{Topic => PartitionsArray} into
%% [#{TopicNameField => Topic, partitions => PartitionsArray}]
tp_map_to_array(TopicNameField, TPM) ->
  maps:fold(
    fun(Topic, Partitions, Acc) ->
        [ #{ TopicNameField => Topic
           , partitions => Partitions
           } | Acc ]
    end, [], TPM).

required_acks(none) -> 0;
required_acks(leader_only) -> 1;
required_acks(all_isr) -> -1;
required_acks(I) when I >= -1 andalso I =< 1 -> I.

encode_struct(API, Vsn, Fields) when ?IS_STRUCT_DATA(Fields) ->
  Schema = kpro_lib:get_req_schema(API, Vsn),
  try
    enc_struct(Schema, Fields, [{API, Vsn}])
  catch
    throw : ?FIELD_ENCODE_ERROR(Reason, Stack) ?BIND_STACKTRACE(Trace) ->
      ?GET_STACKTRACE(Trace),
      erlang:raise(error, {Reason, Stack, Fields}, Trace)
  end;
encode_struct(_API, _Vsn, IoData) ->
  IoData.

%% Encode struct.
enc_struct([], _Values, _Stack) -> [];
enc_struct([{Name, FieldSc} | Schema], Values, Stack) ->
  NewStack = [Name | Stack],
  Value0 =
    try
      kpro_lib:find(Name, Values)
    catch
      error : {no_such_field, tagged_fields} ->
        [];
      error : {no_such_field, _} ->
        erlang:error({field_missing, [ {stack, lists:reverse(NewStack)}
                                     , {input, Values}]})
    end,
  Value = translate(NewStack, Value0),
  [ enc_struct_field(FieldSc, Value, NewStack)
  | enc_struct(Schema, Values, Stack)
  ].

enc_struct_field({array, _Schema}, ?null, _Stack) ->
  encode(int32, -1); %% NULL
enc_struct_field({compact_array, _Schema}, ?null, _Stack) ->
  0; %% NULL
enc_struct_field({A, Schema}, Values, Stack) when A =:= array orelse
                                                  A =:= compact_array ->
  case is_list(Values) of
    true ->
      [ case A of
          array -> encode(int32, length(Values));
          compact_array -> encode(unsigned_varint, length(Values) + 1)
        end
      | [enc_struct_field(Schema, Value, Stack) || Value <- Values]
      ];
    false ->
      erlang:throw(?FIELD_ENCODE_ERROR(not_array, Stack))
  end;
enc_struct_field(Schema, Value, Stack) when ?IS_STRUCT_SCHEMA(Schema) ->
  enc_struct(Schema, Value, Stack);
enc_struct_field(Primitive, Value, Stack) when is_atom(Primitive) ->
  try
    encode(Primitive, Value)
  catch
    error : Reason ?BIND_STACKTRACE(Trace) ->
      ?GET_STACKTRACE(Trace),
      erlang:raise(throw, ?FIELD_ENCODE_ERROR(Reason, Stack), Trace)
  end.

%% Translate embedded bytes to structs or enum values to enum symbols.
translate([isolation_level | _] , Value) ->
  ?ISOLATION_LEVEL_INTEGER(Value);
translate([metadata, protocols | _] = Stack, Value) ->
  Schema = kpro_lib:get_prelude_schema(cg_protocol_metadata, 0),
  bin(enc_struct(Schema, Value, Stack));
translate([assignment, assignments | _] = Stack, Value) ->
  Schema = kpro_lib:get_prelude_schema(cg_memeber_assignment, 0),
  bin(enc_struct(Schema, Value, Stack));
translate([key_type | _], Value) ->
  case Value of
    group -> 0;
    txn -> 1;
    0 -> 0;
    1 -> 1
  end;
translate(_Stack, Value) -> Value.

%% Encode primitives.
encode(Type, Value) -> kpro_lib:encode(Type, Value).

bin(X) -> iolist_to_binary(X).

assert_known_api_and_vsn(API, Vsn) ->
  {Min, Max} =
    try
      kpro_api_vsn:range(API)
    catch
      error : function_clause ->
        erlang:error({unknown_api, API})
    end,
  case Min =< Vsn andalso Vsn =< Max of
    true -> ok;
    false ->
      erlang:error({unknown_vsn, [ {api, API}
                                 , {vsn, Vsn}
                                 , {known_vsn_range, {Min, Max}}
                                 ]})
  end.

transactional_id(false) -> ?kpro_null;
transactional_id(#{transactional_id := TxnId}) -> TxnId.

offset_time(latest) -> -1;
offset_time(earliest) -> -2;
offset_time(T) when is_integer(T) -> T.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
