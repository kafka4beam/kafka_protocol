%%%   Copyright (c) 2014-2018, Klarna AB
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
        ]).

-export([ fetch/7
        , fetch/8
        ]).

-export([ produce/4
        , produce/5
        ]).

-export([ metadata/2
        , metadata/3
        ]).

-export([ add_partitions_to_txn/2
        , end_txn/2
        ]).

-export([ encode/3
        , make/3
        ]).

-include("kpro_private.hrl").
-define(DEFAULT_ACK_TIMEOUT, 10000).

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

%% @doc Make a `metadata' request
-spec metadata(vsn(), all | [topic()]) -> req().
metadata(Vsn, Topics) ->
  metadata(Vsn, Topics, _IsAutoCreateAllowed = false).

%% @doc Make a `metadata' request
-spec metadata(vsn(), all | [topic()], boolean()) -> req().
metadata(Vsn, [], IsAutoCreateAllowed) ->
  metadata(Vsn, all, IsAutoCreateAllowed);
metadata(Vsn, Topics0, IsAutoCreateAllowed) ->
  Topics = case Topics0 of
             all when Vsn =:= 0 -> [];
             all -> ?kpro_null;
             List -> List
           end,
  make(metadata, Vsn, [{topics, Topics},
                       {allow_auto_topic_creation, IsAutoCreateAllowed}]).

%% @doc Help function to contruct a `list_offset' request
%% against one single topic-partition.
-spec list_offsets(vsn(), topic(), partition(), msg_ts()) -> req().
list_offsets(Vsn, Topic, Partition, Time) ->
  list_offsets(Vsn, Topic, Partition, Time, ?kpro_read_committed).

%% @doc Help function to contruct a `list_offset' request against one single
%% topic-partition. In transactional mode,
%% set `IsolationLevel = ?kpro_read_uncommitted' to list uncommited offsets.
-spec list_offsets(vsn(), topic(), partition(),
                   latest | earliest | msg_ts(),
                   isolation_level()) -> req().
list_offsets(Vsn, Topic, Partition, latest, IsolationLevel) ->
  list_offsets(Vsn, Topic, Partition, -1, IsolationLevel);
list_offsets(Vsn, Topic, Partition, earliest, IsolationLevel) ->
  list_offsets(Vsn, Topic, Partition, -2, IsolationLevel);
list_offsets(Vsn, Topic, Partition, Time, IsolationLevel) ->
  PartitionFields =
    case Vsn of
      0 ->
        [{partition, Partition},
         {timestamp, Time},
         {max_num_offsets, 1}];
      _ ->
        %% max_num_offsets is removed since version 1
        [{partition, Partition},
         {timestamp, Time}
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
%% against one single topic-partition.
fetch(Vsn, Topic, Partition, Offset, MaxWaitTime, MinBytes, MaxBytes) ->
  fetch(Vsn, Topic, Partition, Offset, MaxWaitTime, MinBytes, MaxBytes,
        ?kpro_read_committed).

%% @doc Help function to construct a `fetch' request
%% against one single topic-partition. In transactional mode, set
%% `IsolationLevel = kpro_read_uncommitted' to fetch uncommitted messages.
-spec fetch(vsn(), topic(), partition(), offset(), wait(), count(), count(),
            isolation_level()) -> req().
fetch(Vsn, Topic, Partition, Offset, MaxWaitTime,
      MinBytes, MaxBytes, IsolationLevel) ->
  Fields =
    [{replica_id, ?KPRO_REPLICA_ID},
     {max_wait_time, MaxWaitTime},
     {max_bytes, MaxBytes},
     {min_bytes, MinBytes},
     {isolation_level, IsolationLevel},
     {topics,[[{topic, Topic},
               {partitions,
                [[{partition, Partition},
                  {fetch_offset, Offset},
                  {max_bytes, MaxBytes},
                  {log_start_offset, -1} %% irelevant to clients
                 ]]}]]}],
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
%% 2. `first_sequence' must exist in `Opts'.
%%     It should be the sequence number for the fist message in batch.
%%     Maintained by producr, sequence numbers should start from zero and be
%%     monotonically increasing, with one sequence number per topic-partition.
%% 3. `txn_ctx' (which is of spec `kpro:txn_ctx()') must exist in `Opts'
-spec produce(vsn(), topic(), partition(),
              batch_input(), produce_opts()) -> req().
produce(Vsn, Topic, Partition, Batch, Opts) ->
  RequiredAcks = required_acks(maps:get(required_acks, Opts, all_isr)),
  Compression = maps:get(compression, Opts, ?no_compression),
  AckTimeout = maps:get(ack_timeout, Opts, ?DEFAULT_ACK_TIMEOUT),
  TxnCtx = maps:get(txn_ctx, Opts, false),
  FirstSequence = maps:get(first_sequence, Opts, -1),
  EncodedBatch =
    case TxnCtx of
      false ->
        kpro_batch:encode(Batch, Compression);
      TxnCtx ->
        true = FirstSequence >= 0, %% assert
        kpro_batch:encode_tx(Batch, Compression, FirstSequence, TxnCtx)
    end,
  Fields =
    [{transactional_id, transactional_id(TxnCtx)},
     {acks, RequiredAcks},
     {timeout, AckTimeout},
     {topic_data, [[{topic, Topic},
                    {data, [[{partition, Partition},
                             {record_set, EncodedBatch}
                            ]]}
                   ]]}
    ],
  Req = make(produce, Vsn, Fields),
  Req#kpro_req{no_ack = RequiredAcks =:= 0}.

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
  Groupped =
  lists:foldl(
    fun({Topic, Partition}, Acc) ->
        kpro_lib:update_map(
          Topic, fun(PL) -> [Partition | PL] end,
          [Partition], Acc)
    end, #{}, TopicPartitionList),
  Topics =
  maps:fold(
    fun(Topic, Partitions, Acc) ->
        [#{ topic => Topic
          , partitions => Partitions
          } | Acc]
    end, [], Groupped),
  Body = TxnCtx#{topics => Topics},
  make(add_partitions_to_txn, _Vsn = 0, Body).

%% @doc Help function to make a request body.
-spec make(api(), vsn(), struct()) -> req().
make(API, Vsn, Fields) ->
  ok = assert_known_api_and_vsn(API, Vsn),
  #kpro_req{ api = API
           , vsn = Vsn
           , msg = encode_struct(API, Vsn, Fields)
           }.

%% @doc Encode a request to bytes that can be sent on wire.
-spec encode(client_id(), corr_id(), req()) -> iodata().
encode(ClientName, CorrId, Req) ->
  #kpro_req{api = API, vsn = Vsn, msg = Msg} = Req,
  ApiKey = kpro_schema:api_key(API),
  IoData =
    [ encode(int16, ApiKey)
    , encode(int16, Vsn)
    , encode(int32, CorrId)
    , encode(string, ClientName)
    , encode_struct(API, Vsn, Msg)
    ],
  Size = kpro_lib:data_size(IoData),
  [encode(int32, Size), IoData].

%%%_* Internal functions =======================================================

required_acks(none) -> 0;
required_acks(leader_only) -> 1;
required_acks(all_isr) -> -1;
required_acks(I) when I >= -1 andalso I =< 1 -> I.

encode_struct(_API, _Vsn, Bin) when is_binary(Bin) -> Bin;
encode_struct(API, Vsn, Fields) ->
  Schema = kpro_lib:get_req_schema(API, Vsn),
  try
    bin(enc_struct(Schema, Fields, [{API, Vsn}]))
  catch
    throw : {Reason, Stack} ->
      Trace = erlang:get_stacktrace(),
      erlang:raise(error, {Reason, Stack, Fields}, Trace)
  end.

%% Encode struct.
enc_struct([], _Values, _Stack) -> [];
enc_struct([{Name, FieldSc} | Schema], Values, Stack) ->
  NewStack = [Name | Stack],
  Value0 = kpro_lib:find(Name, Values,
                         {field_missing, [ {stack, lists:reverse(NewStack)}
                                         , {input, Values}]}),
  Value = translate(NewStack, Value0),
  [ enc_struct_field(FieldSc, Value, NewStack)
  | enc_struct(Schema, Values, Stack)
  ].

enc_struct_field({array, _Schema}, ?null, _Stack) ->
  encode(int32, -1); %% NULL
enc_struct_field({array, Schema}, Values, Stack) ->
  case is_list(Values) of
    true ->
      [ encode(int32, length(Values))
      | [enc_struct_field(Schema, Value, Stack) || Value <- Values]
      ];
    false ->
      erlang:throw({not_array, Stack})
  end;
enc_struct_field(Schema, Value, Stack) when ?IS_STRUCT(Schema) ->
  enc_struct(Schema, Value, Stack);
enc_struct_field(Primitive, Value, Stack) when is_atom(Primitive) ->
  try
    encode(Primitive, Value)
  catch
    error : Reason ->
      erlang:throw({Reason, Stack, erlang:get_stacktrace()})
  end.

%% Translate embedded bytes to structs or enum values to enum symbols.
translate([isolation_level | _] , Value) ->
  ?ISOLATION_LEVEL_INTEGER(Value);
translate([protocol_metadata | _] = Stack, Value) ->
  Schema = kpro_lib:get_prelude_schema(cg_protocol_metadata, 0),
  bin(enc_struct(Schema, Value, Stack));
translate([member_assignment | _] = Stack, Value) ->
  Schema = kpro_lib:get_prelude_schema(cg_memeber_assignment, 0),
  bin(enc_struct(Schema, Value, Stack));
translate([coordinator_type | _], Value) ->
  case Value of
    group -> 0;
    txn -> 1;
    0 -> 0;
    1 -> 1
  end;
translate(_Stack, Value) -> Value.

%% Encode prmitives.
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

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
