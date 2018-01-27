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

-module(kpro).

%% APIs to build requests.
-export([ fetch_request/7
        , offsets_request/4
        , produce_request/6
        , produce_request/7
        , find/2
        , find/3
        , req/3
        , max_corr_id/0
        ]).

%% APIs for the socket process
-export([ decode_response/1
        , decode_batches/1
        , encode_request/3
        , next_corr_id/1
        ]).

%% Hidden APIs
-export([ dec_struct/4
        , decode/2
        , decode_struct/3
        , decode_struct/4
        , enc_struct/3
        , encode/2
        , encode_struct/3
        , encode_struct/4
        , get_schema/2
        , get_schema/3
        ]).

-export_type([ batch_decode_result/0
             , batch_input/0
             , batch_meta/0
             , bytes/0
             , client_id/0
             , compress_option/0
             , corr_id/0
             , count/0
             , error_code/0
             , field_name/0
             , field_value/0
             , headers/0
             , header_key/0
             , header_val/0
             , hostname/0
             , incomplete_batch/0
             , int8/0
             , int16/0
             , int32/0
             , int64/0
             , key/0
             , kv_list/0
             , magic/0
             , message/0
             , meta_input/0
             , msg_ts/0
             , offset/0
             , partition/0
             , portnum/0
             , primitive/0
             , primitive_type/0
             , producer_id/0
             , req/0
             , req_tag/0
             , rsp/0
             , rsp_tag/0
             , schema/0
             , str/0
             , struct/0
             , tag/0
             , timestamp_type/0
             , topic/0
             , value/0
             , vsn/0
             , wait/0
             ]).

-include("kpro_private.hrl").

-type int8()       :: -128..127.
-type int16()      :: -32768..32767.
-type int32()      :: -2147483648..2147483647.
-type int64()      :: -9223372036854775808..9223372036854775807.
-type str()        :: ?null | string() | binary().
-type bytes()      :: ?null | binary().
-type error_code() :: int16() | atom().
-type msg_ts() :: int64().
-type producer_id() :: int64().
-type magic() :: int8().

-type client_id() :: binary().
-type hostname() :: binary() | string().
-type portnum() :: non_neg_integer().
-type corr_id() :: int32().
-type topic() :: binary().
-type partition() :: int32().
-type offset() :: int64().

% Attribute :: {compression, kpro:compress_option()}
%            | {ts_type, kpro:timestamp_type()}
%            | is_transaction | {is_transaction, boolean()}
%            | is_control | {is_control, boolean()}.
-type batch_attributes() :: proplists:proplist().

-type header_key() :: binary().
-type header_val() :: binary().
-type headers() :: [{header_key(), header_val()}].

-type key() :: ?null | iodata().
-type value() :: ?null | iodata().
-type value_mabye_nested() :: value() | [{key(), kv_list()}].
-type kv_list() :: [kv() | tkv()].

-type msg_key() :: headers | ts | key | value.
-type msg_val() :: headers() | msg_ts() | key() | value().

-type kv() :: {key(), value_mabye_nested()}. % magic 0
-type tkv() :: {msg_ts(), key(), value_mabye_nested()}. % magic 1
-type msg_input() :: #{msg_key() => msg_val()}. % magic 2

-type meta_input() :: #{}.
-type batch_input() :: [kv()] % magic 0
                     | [tkv()] % magic 1
                     | [msg_input()]. % magic 2 non-transactional

-type incomplete_batch() :: ?incomplete_batch(int32()).
-type message() :: #kafka_message{}.
-type batch_meta() :: ?KPRO_NO_BATCH_META %% magic 0-1
                    | #kpro_batch_meta{}.
-type batch_decode_result() :: ?incomplete_batch(int32())
                             | {batch_meta(), [message()]}.

-type vsn() :: non_neg_integer().
-type count() :: non_neg_integer().
-type wait() :: non_neg_integer().
-type required_acks() :: -1..1.
-type primitive() :: integer() | string() | binary() | atom().
-type field_name() :: atom().
-type field_value() :: primitive() | struct() | [struct()].
-type struct() :: [{field_name(), field_value()}].
-type req_tag() :: atom().
-type rsp_tag() :: atom().
-type tag() :: req_tag() | rsp_tag().
-type req() :: #kpro_req{}.
-type rsp() :: #kpro_rsp{}.
-type compress_option() :: ?no_compression
                         | ?gzip
                         | ?snappy
                         | ?lz4.
-type timestamp_type() :: undefined | create | append.
-type primitive_type() :: boolean
                        | int8
                        | int16
                        | int32
                        | int64
                        | varint
                        | string
                        | nullable_string
                        | bytes
                        | records.
-type decode_fun() :: fun((binary()) -> {field_value(), binary()}).
-type struct_schema() :: [{field_name(), schema()}].
-type schema() :: primitive_type()
                | struct_schema()
                | {array, schema()}
                | decode_fun(). %% caller defined decoder
-type stack() :: [{tag(), vsn()} | field_name()]. %% encode / decode stack

-define(SCHEMA_MODULE, kpro_schema).
-define(PRELUDE, kpro_prelude_schema).
%% All versions of kafka messages (records) share the same header:
%% Offset => int64
%% Length => int32
%% We need to at least fetch 12 bytes in order to fetch:
%%  - one complete message when it's magic v0-1 not compressed
%%  - one comprete batch when it's v0-1 compressed batch
%%    v0-1 compressed batch is embedded in a wrapper message (i.e. recursive)
%%  - one complete batch when it is v2.
%%    v2 batch is flat and trailing the batch header.
-define(BATCH_LEADING_BYTES, 12).

%%%_* APIs =====================================================================

%% @doc Return the allowed maximum correlation ID.
-spec max_corr_id() -> corr_id().
max_corr_id() -> ?MAX_CORR_ID.

%% @doc Help function to contruct a OffsetsRequest
%% against one single topic-partition.
%% @end
-spec offsets_request(vsn(), topic(), partition(), msg_ts()) -> req().
offsets_request(Vsn, Topic, Partition, Time) ->
  PartitionFields =
    case Vsn of
      0 ->
        [{partition, Partition},
         {timestamp, Time},
         {max_num_offsets, 1}];
      1 ->
        [{partition, Partition},
         {timestamp, Time}]
    end,
  Fields =
    [{replica_id, ?KPRO_REPLICA_ID},
     {topics, [ [{topic, Topic},
                 {partitions, [ PartitionFields ]}]
              ]}
    ],
  req(offsets_request, Vsn, Fields).

%% @doc Help function to construct a FetchRequest
%% against one single topic-partition.
%% @end
-spec fetch_request(vsn(), topic(), partition(), offset(),
                    wait(), count(), count()) -> req().
fetch_request(Vsn, Topic, Partition, Offset,
              MaxWaitTime, MinBytes, MaxBytes) ->
  Fields0 =
    [{replica_id, ?KPRO_REPLICA_ID},
     {max_wait_time, MaxWaitTime},
     {min_bytes, MinBytes},
     {topics,[[{topic, Topic},
               {partitions,
                [[{partition, Partition},
                  {fetch_offset, Offset},
                  {max_bytes, MaxBytes}]]}]]}],
  %% Version 3 introduced a top level max_bytes
  %% we use the same value as per-partition max_bytes
  %% because this API is to build request against single partition
  Fields =
    case Vsn >= 3 of
      true  -> [{max_bytes, MaxBytes} | Fields0];
      false -> Fields0
    end,
  req(fetch_request, Vsn, Fields).

%% @equiv produce_request(Vsn, Topic, Partition, KvList, RequiredAcks,
%%                        AckTimeout, ?no_compression)
%% @end
-spec produce_request(vsn(), topic(), partition(), batch_input(),
                      required_acks(), wait()) -> req().
produce_request(Vsn, Topic, Partition, Batch, RequiredAcks, AckTimeout) ->
  produce_request(Vsn, Topic, Partition, Batch, RequiredAcks, AckTimeout,
                  ?no_compression).

%% @doc Help function to construct a produce request for
%% messages targeting one single topic-partition.
%% @end
-spec produce_request(vsn(), topic(), partition(), batch_input(),
                      required_acks(), wait(), compress_option()) -> req().
produce_request(Vsn, Topic, Partition, Batch,
                RequiredAcks, AckTimeout, CompressOption) ->
  Messages = kpro_batch:encode(Batch, CompressOption),
  Fields =
    [{acks, RequiredAcks},
     {timeout, AckTimeout},
     {topic_data, [[{topic, Topic},
                    {data, [[{partition, Partition},
                             {record_set, Messages}
                            ]]}
                   ]]}
    ],
  Req = req(produce_request, Vsn, Fields),
  Req#kpro_req{no_ack = RequiredAcks =:= 0}.

%% @doc Help function to make a request body.
-spec req(req_tag(), vsn(), struct()) -> req().
req(Tag, Vsn, Fields) ->
  #kpro_req{ tag = Tag
           , vsn = Vsn
           , msg = encode_struct(Tag, Vsn, Fields)
           }.

%% @doc Get the next correlation ID.
-spec next_corr_id(corr_id()) -> corr_id().
next_corr_id(?MAX_CORR_ID) -> 0;
next_corr_id(CorrId)       -> CorrId + 1.

%% @doc Encode a request to bytes that can be sent on wire.
-spec encode_request(client_id(), corr_id(), req()) -> iodata().
encode_request(ClientName, CorrId0, Req) ->
  #kpro_req{tag = Tag, vsn = Vsn, msg = Msg} = Req,
  ApiKey = ?REQ_TO_API_KEY(Tag),
  true = (CorrId0 =< ?MAX_CORR_ID), %% assert
  true = (ApiKey < 1 bsl ?API_KEY_BITS), %% assert
  true = (Vsn < 1 bsl ?API_VERSION_BITS), %% assert
  CorrId = <<ApiKey:?API_KEY_BITS,
             Vsn:?API_VERSION_BITS,
             CorrId0:?CORR_ID_BITS>>,
  IoData =
    [ encode(int16, ApiKey)
    , encode(int16, Vsn)
    , CorrId
    , encode(string, ClientName)
    , encode_struct(Tag, Vsn, Msg)
    ],
  Size = kpro_lib:data_size(IoData),
  [encode(int32, Size), IoData].

%% @doc Parse binary stream received from kafka broker.
%% Return a list of kpro:rsp() and the remaining bytes.
%% @end
-spec decode_response(binary()) -> {[rsp()], binary()}.
decode_response(Bin) ->
  decode_response(Bin, []).

%% @doc The messageset is not decoded upon receiving (in socket process).
%% Pass the message set as binary to the consumer process and decode there
%% Return `?incomplete_batch(ExpectedSize)' if the fetch size is not big
%% enough for even one single message. Otherwise return `{Meta, Messages}'
%% where `Meta' is either `?KPRO_NO_BATCH_META' for magic-version 0-1 or
%% `#kafka_batch_meta{}' for magic-version 2 or above.
-spec decode_batches(binary()) -> batch_decode_result().
decode_batches(<<_:64/?INT, L:32, T/binary>> = Bin) when size(T) >= L ->
  kpro_batch:decode(Bin);
decode_batches(<<_:64/?INT, L:32, _T/binary>>) ->
  %% not enough to decode one single message for magic v0-1
  %% or a single batch for magic v2
  ?incomplete_batch(L + ?BATCH_LEADING_BYTES);
decode_batches(_) ->
  %% not enough to even get the size header
  ?incomplete_batch(?BATCH_LEADING_BYTES).

%%%_* Hidden APIs ==============================================================

%% @hidden Encode prmitives.
-spec encode(primitive_type(), primitive()) -> iodata().
encode(Type, Value) -> kpro_lib:encode(Type, Value).

%% @hidden Decode prmitives.
-spec decode(primitive_type(), binary()) -> {primitive(), binary()}.
decode(Type, Bin) -> kpro_lib:decode(Type, Bin).

%% @hidden Encode struct.
-spec enc_struct(schema(), struct(), stack()) -> iodata().
enc_struct([], _Values, _Stack) -> [];
enc_struct([{Name, FieldSc} | Schema], Values, Stack) when is_list(Values) ->
  NewStack = [Name | Stack],
  case lists:keytake(Name, 1, Values) of
    {value, {_, Value0}, ValuesLeft} ->
      Value = enc_embedded(NewStack, Value0),
      [ enc_struct_field(FieldSc, Value, NewStack)
      | enc_struct(Schema, ValuesLeft, Stack)
      ];
    false ->
      erlang:throw({field_missing, [Name | Stack]})
  end;
enc_struct(_Schema, _Value, Stack) ->
  erlang:throw({not_struct, Stack}).

%% @hidden Decode struct.
-spec dec_struct(struct_schema(), struct(), stack(), binary()) ->
        {struct(), binary()}.
dec_struct([], Fields, _Stack, Bin) ->
  {lists:reverse(Fields), Bin};
dec_struct([{Name, FieldSc} | Schema], Fields, Stack, Bin) ->
  NewStack = [Name | Stack],
  {Value0, Rest} = dec_struct_field(FieldSc, NewStack, Bin),
  Value = dec_embedded(NewStack, Value0),
  dec_struct(Schema, [{Name, Value} | Fields], Stack, Rest).

%% @hidden Encode struct having schema predefined in kpro_schema.
-spec encode_struct(req_tag(), vsn(), binary() | struct()) -> binary().
encode_struct(Tag, Vsn, Bin) ->
  encode_struct(?SCHEMA_MODULE, Tag, Vsn, Bin).

%% @hidden Encode struct having schema predefined in a callback:
%% Module:get(Tag, Vsn)
%% @end
-spec encode_struct(module(), req_tag(), vsn(),
                    binary() | struct()) -> binary().
encode_struct(_Module, _Tag, _Vsn, Bin) when is_binary(Bin) -> Bin;
encode_struct(Module, Tag, Vsn, Fields) ->
  Schema = get_schema(Module, Tag, Vsn),
  try
    bin(enc_struct(Schema, Fields, [{Tag, Vsn}]))
  catch
    throw : {Reason, Stack} ->
      Trace = erlang:get_stacktrace(),
      erlang:raise(error, {Reason, Stack, Fields}, Trace)
  end.

%% @hidden Decode struct having schema predefined in kpro_schema.
-spec decode_struct(rsp_tag(), vsn(), binary()) ->
        {struct(), binary()}.
decode_struct(Tag, Vsn, Bin) ->
  decode_struct(?SCHEMA_MODULE, Tag, Vsn, Bin).

%% @hidden Decode struct having schema predefined in a callback:
%% Module:get(Tag, Vsn)
%% @end
-spec decode_struct(module(), rsp_tag(), vsn(), binary()) ->
        {struct(), binary()}.
decode_struct(Module, Tag, Vsn, Bin) ->
  Schema = get_schema(Module, Tag, Vsn),
  dec_struct(Schema, _Fields = [], _Stack = [{Tag, Vsn}], Bin).

%% @hidden Get predefined schema from kpro_schema:get/2.
-spec get_schema(tag(), vsn()) -> struct_schema().
get_schema(Tag, Vsn) ->
  get_schema(?SCHEMA_MODULE, Tag, Vsn).

%% @hidden Get predefined schema from Module:get/2 API.
-spec get_schema(module(), tag(), vsn()) -> struct_schema().
get_schema(Module, Tag, Vsn) ->
  try
    Module:get(Tag, Vsn)
  catch
    error : function_clause when Vsn =:= 0 ->
      erlang:error({unknown_tag, Tag});
    error : function_clause when Vsn > 0 ->
      try
        _ = Module:get(Tag, 0)
      catch
        error : function_clause ->
          erlang:error({unknown_tag, Tag})
      end,
      erlang:error({unsupported_version, Tag, Vsn})
  end.

%% @doc Find field value in a struct, raise an exception if not found.
-spec find(field_name(), struct()) -> field_value() | no_return().
find(Field, Struct) ->
  case lists:keyfind(Field, 1, Struct) of
    {_, Value} -> Value;
    false -> erlang:throw({no_such_field, Field})
  end.

%% @doc Find field value in a struct, reutrn default if not found.
-spec find(field_name(), struct(), field_value()) -> field_value().
find(Field, Struct, Default) ->
  try
    find(Field, Struct)
  catch
    throw : {no_such_field, _} ->
      Default
  end.

%%%_* Internal functions =======================================================

-spec decode_response(binary(), [rsp()]) -> {[rsp()], binary()}.
decode_response(Bin, Acc) ->
  case do_decode_response(Bin) of
    {incomplete, Rest} ->
      {lists:reverse(Acc), Rest};
    {Response, Rest} ->
      decode_response(Rest, [Response | Acc])
  end.

%% Decode responses received from kafka broker.
%% {incomplete, TheOriginalBinary} is returned if this is not a complete packet.
-spec do_decode_response(binary()) -> {incomplete | rsp(), binary()}.
do_decode_response(<<Size:32/?INT, Bin/binary>>) when size(Bin) >= Size ->
  << ApiKey:?API_KEY_BITS,
     Vsn:?API_VERSION_BITS,
     CorrId:?CORR_ID_BITS,
     Rest0/binary >> = Bin,
  Tag = ?API_KEY_TO_RSP(ApiKey),
  {Message, Rest} =
    try
      decode_struct(Tag, Vsn, Rest0)
    catch error : E ->
      Context = [ {tag, Tag}
                , {vsn, Vsn}
                , {corr_id, CorrId}
                , {payload, Bin}
                ],
      Trace = erlang:get_stacktrace(),
      erlang:raise(error, {E, Context}, Trace)
    end,
  Result =
    #kpro_rsp{ tag = Tag
             , vsn = Vsn
             , corr_id = CorrId
             , msg = Message
             },
  {Result, Rest};
do_decode_response(Bin) ->
  {incomplete, Bin}.

-spec enc_struct_field(schema(), struct(), stack()) -> iodata().
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
enc_struct_field(Schema, Value, Stack) when is_list(Schema) ->
  enc_struct(Schema, Value, Stack);
enc_struct_field(Primitive, Value, Stack) when is_atom(Primitive) ->
  try
    encode(Primitive, Value)
  catch
    error : Reason ->
      erlang:throw({Reason, Stack})
  end.

%% Encode embedded bytes.
-spec enc_embedded(stack(), field_value()) -> field_value().
enc_embedded([protocol_metadata | _] = Stack, Value) ->
  Schema = get_schema(?PRELUDE, cg_protocol_metadata, 0),
  bin(enc_struct(Schema, Value, Stack));
enc_embedded([member_assignment | _] = Stack, Value) ->
  Schema = get_schema(?PRELUDE, cg_memeber_assignment, 0),
  bin(enc_struct(Schema, Value, Stack));
enc_embedded(_Stack, Value) -> Value.

%% A struct field should have one of below types:
%% 1. An array of any
%% 2. Another struct
%% 3. A user define decoder
%% 4. A primitive
-spec dec_struct_field(schema(), stack(), binary()) ->
        {field_value(), binary()}.
dec_struct_field({array, Schema}, Stack, Bin0) ->
  {Count, Bin} = decode(int32, Bin0),
  case Count =:= -1 of
    true -> {?null, Bin};
    false -> dec_array_elements(Count, Schema, Stack, Bin, [])
  end;
dec_struct_field(Schema, Stack, Bin) when is_list(Schema) ->
  dec_struct(Schema, [], Stack, Bin);
dec_struct_field(F, _Stack, Bin) when is_function(F) ->
  %% Caller provided decoder
  F(Bin);
dec_struct_field(Primitive, Stack, Bin) when is_atom(Primitive) ->
  try
    decode(Primitive, Bin)
  catch
    error : _Reason ->
      erlang:error({Stack, Primitive, Bin})
  end.

-spec dec_array_elements(count(), schema(), stack(), binary(), Acc) ->
        {Acc, binary()} when Acc :: [field_value()].
dec_array_elements(0, _Schema, _Stack, Bin, Acc) ->
  {lists:reverse(Acc), Bin};
dec_array_elements(N, Schema, Stack, Bin, Acc) ->
  {Element, Rest} = dec_struct_field(Schema, Stack, Bin),
  dec_array_elements(N-1, Schema, Stack, Rest, [Element | Acc]).

%% Translate error codes; Dig up embedded bytes.
-spec dec_embedded(stack(), field_value()) -> field_value().
dec_embedded([error_code | _], ErrorCode) ->
  kpro_error_code:decode(ErrorCode);
dec_embedded([topic_error_code | _], ErrorCode) ->
  kpro_error_code:decode(ErrorCode);
dec_embedded([partition_error_code | _], ErrorCode) ->
  kpro_error_code:decode(ErrorCode);
dec_embedded([member_metadata | _] = Stack, Bin) ->
  Schema = get_schema(?PRELUDE, cg_member_metadata, 0),
  case Bin =:= <<>> of
    true  -> ?kpro_cg_no_member_metadata;
    false -> dec_struct_clean(Schema, [{cg_member_metadata, 0} | Stack], Bin)
  end;
dec_embedded([member_assignment | _], <<>>) ->
  ?kpro_cg_no_assignment; %% no assignment for this member
dec_embedded([member_assignment | _] = Stack, Bin) ->
  Schema = get_schema(?PRELUDE, cg_memeber_assignment, 0),
  dec_struct_clean(Schema, [{cg_memeber_assignment, 0} | Stack], Bin);
dec_embedded([api_key | _], ApiKey) ->
  ?API_KEY_TO_REQ(ApiKey);
dec_embedded(_Stack, Value) ->
  Value.

%% Decode struct, assume no tail bytes.
-spec dec_struct_clean(schema(), stack(), binary()) -> struct().
dec_struct_clean(Schema, Stack, Bin) ->
  {Fields, <<>>} = dec_struct(Schema, [], Stack, Bin),
  Fields.

-spec bin(iodata()) -> binary().
bin(X) -> iolist_to_binary(X).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
