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

-export([ produce/6
        , produce/7
        ]).

-export([ metadata/2
        , metadata/3
        ]).

-export([ encode/3
        , make/3
        ]).

-include("kpro_private.hrl").

%% @doc Make a `metadata' request
-spec metadata(kpro:vsn(), all | [kpro:topic()]) -> kpro:req().
metadata(Vsn, Topics) ->
  metadata(Vsn, Topics, _IsAutoCreateAllowed = false).

%% @doc Make a `metadata' request
-spec metadata(kpro:vsn(), all | [kpro:topic()], boolean()) -> kpro:req().
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
-spec list_offsets(kpro:vsn(), kpro:topic(), kpro:partition(),
                   kpro:msg_ts()) -> kpro:req().
list_offsets(Vsn, Topic, Partition, Time) ->
  list_offsets(Vsn, Topic, Partition, Time, ?kpro_read_committed).

%% @doc Help function to contruct a `list_offset' request against one single
%% topic-partition. In transactional mode,
%% set `IsolationLevel = ?kpro_read_uncommitted' to list uncommited offsets.
-spec list_offsets(kpro:vsn(), kpro:topic(), kpro:partition(),
                   latest | earliest | kpro:msg_ts(),
                   kpro:isolation_level()) -> kpro:req().
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
-spec fetch(kpro:vsn(), kpro:topic(), kpro:partition(), kpro:offset(),
            kpro:wait(), kpro:count(), kpro:count(),
            kpro:isolation_level()) -> kpro:req().
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

%% @equiv produce(Vsn, Topic, Partition, KvList, RequiredAcks,
%%                AckTimeout, ?no_compression)
-spec produce(kpro:vsn(), kpro:topic(), kpro:partition(), kpro:batch_input(),
              kpro:required_acks(), kpro:wait()) -> kpro:req().
produce(Vsn, Topic, Partition, Batch, RequiredAcks, AckTimeout) ->
  produce(Vsn, Topic, Partition, Batch, RequiredAcks, AckTimeout,
          ?no_compression).

%% @doc Help function to construct a produce request for
%% messages targeting one single topic-partition.
-spec produce(kpro:vsn(), kpro:topic(), kpro:partition(), kpro:batch_input(),
              kpro:required_acks(), kpro:wait(), kpro:compress_option()) ->
        kpro:req().
produce(Vsn, Topic, Partition, Batch, RequiredAcks,
        AckTimeout, CompressOption) ->
  Messages = kpro_batch:encode(Batch, CompressOption),
  Fields =
    [{transactional_id, ?kpro_null},
     {acks, RequiredAcks},
     {timeout, AckTimeout},
     {topic_data, [[{topic, Topic},
                    {data, [[{partition, Partition},
                             {record_set, Messages}
                            ]]}
                   ]]}
    ],
  Req = make(produce, Vsn, Fields),
  Req#kpro_req{no_ack = RequiredAcks =:= 0}.

%% @doc Help function to make a request body.
-spec make(kpro:api(), kpro:vsn(), kpro:struct()) -> kpro:req().
make(API, Vsn, Fields) ->
  #kpro_req{ api = API
           , vsn = Vsn
           , msg = encode_struct(API, Vsn, Fields)
           }.

%% @doc Encode a request to bytes that can be sent on wire.
-spec encode(kpro:client_id(), kpro:corr_id(), kpro:req()) -> iodata().
encode(ClientName, CorrId, Req) ->
  #kpro_req{api = API, vsn = Vsn, msg = Msg} = Req,
  ApiKey = ?API_KEY_INTEGER(API),
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
  Value0 = kpro:do_find(Name, Values, {field_missing, NewStack}),
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
  Schema = kpro:get_prelude_schema(cg_protocol_metadata, 0),
  bin(enc_struct(Schema, Value, Stack));
translate([member_assignment | _] = Stack, Value) ->
  Schema = kpro:get_prelude_schema(cg_memeber_assignment, 0),
  bin(enc_struct(Schema, Value, Stack));
translate(_Stack, Value) -> Value.

%% Encode prmitives.
encode(Type, Value) -> kpro_lib:encode(Type, Value).

bin(X) -> iolist_to_binary(X).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
