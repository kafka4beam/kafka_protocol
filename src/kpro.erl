%%%   Copyright (c) 2014-2017, Klarna AB
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
        , decode_message_set/1
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

-export_type([ bytes/0
             , client_id/0
             , compress_option/0
             , corr_id/0
             , count/0
             , error_code/0
             , field_name/0
             , field_value/0
             , incomplete_message/0
             , int8/0
             , int16/0
             , int32/0
             , int64/0
             , key/0
             , kv_list/0
             , message/0
             , msg_ts/0
             , offset/0
             , partition/0
             , primitive_type/0
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
-type msg_ts() :: integer().

%% type re-define for readability
-type client_id() :: str().
-type corr_id()   :: int32().
-type topic()     :: str().
-type partition() :: int32().
-type offset()    :: int64().

-type key() :: ?null | iodata().
-type value() :: ?null | iodata() | [{key(), kv_list()}].
-type kv_list() :: [{key(), value()} | {msg_ts(), key(), value()}].

-type incomplete_message() :: ?incomplete_message(int32()).
-type message() :: #kafka_message{}.
-type decoded_message() :: incomplete_message() | message().

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
-type compress_option() :: no_compression | gzip | snappy | lz4.
-type timestamp_type() :: undefined | create | append.
-type primitive_type() :: boolean
                        | int8
                        | int16
                        | int32
                        | int64
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

-define(INT, signed-integer).
-define(SCHEMA_MODULE, kpro_schema).
-define(PRELUDE, kpro_prelude_schema).
-define(NO_TIMESTAMP, -1).

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
%%                        AckTimeout, no_compression)
%% @end
-spec produce_request(vsn(), topic(), partition(), kv_list(),
                      required_acks(), wait()) -> req().
produce_request(Vsn, Topic, Partition, KvList, RequiredAcks, AckTimeout) ->
  produce_request(Vsn, Topic, Partition, KvList, RequiredAcks, AckTimeout,
                  no_compression).

%% @doc Help function to construct a produce request for
%% messages targeting one single topic-partition.
%% @end
-spec produce_request(vsn(), topic(), partition(), kv_list(),
                      required_acks(), wait(), compress_option()) -> req().
produce_request(Vsn, Topic, Partition, KvList,
                RequiredAcks, AckTimeout, CompressOption) ->
  Messages = encode_messages(KvList, CompressOption),
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
encode_request(ClientId, CorrId0, Req) ->
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
    , encode(string, ClientId)
    , encode_struct(Tag, Vsn, Msg)
    ],
  Size = data_size(IoData),
  [encode(int32, Size), IoData].

%% @doc Parse binary stream received from kafka broker.
%% Return a list of kpro:rsp() and the remaining bytes.
%% @end
-spec decode_response(binary()) -> {[rsp()], binary()}.
decode_response(Bin) ->
  decode_response(Bin, []).

%% @doc The messageset is not decoded upon receiving (in socket process).
%% Pass the message set as binary to the consumer process and decode there
%% Return {incomplete_message, ExpectedSize} if the fetch size is not big
%% enough for even one single message. Otherwise return a list of decoded
%% messages.
%% @end
-spec decode_message_set(binary()) -> incomplete_message() | [message()].
decode_message_set(MessageSetBin) when is_binary(MessageSetBin) ->
  case decode_message_stream(MessageSetBin, []) of
    [?incomplete_message(_) = Incomplete] ->
      %% The only message is incomplete
      %% return the special tuple
      Incomplete;
    [?incomplete_message(_) | Messages] ->
      %% Discard the last incomplete message
      lists:reverse(Messages);
    Messages ->
      lists:reverse(Messages)
  end.

%%%_* Hidden APIs ==============================================================

%% @hidden Encode prmitives.
-spec encode(primitive_type(), primitive()) -> iodata().
encode(boolean, true) -> <<1:8/?INT>>;
encode(boolean, false) -> <<0:8/?INT>>;
encode(int8,  I) when is_integer(I) -> <<I:8/?INT>>;
encode(int16, I) when is_integer(I) -> <<I:16/?INT>>;
encode(int32, I) when is_integer(I) -> <<I:32/?INT>>;
encode(int64, I) when is_integer(I) -> <<I:64/?INT>>;
encode(nullable_string, ?null) -> <<-1:16/?INT>>;
encode(nullable_string, Str) -> encode(string, Str);
encode(string, Atom) when is_atom(Atom) ->
  encode(string, atom_to_binary(Atom, utf8));
encode(string, <<>>) -> <<0:16/?INT>>;
encode(string, L) when is_list(L) ->
  encode(string, bin(L));
encode(string, B) when is_binary(B) ->
  Length = size(B),
  <<Length:16/?INT, B/binary>>;
encode(bytes, ?null) -> <<-1:32/?INT>>;
encode(bytes, B) when is_binary(B) orelse is_list(B) ->
  Size = data_size(B),
  case Size =:= 0 of
    true  -> <<-1:32/?INT>>;
    false -> [<<Size:32/?INT>>, B]
  end;
encode(records, B) ->
  encode(bytes, B).

%% @hidden Decode prmitives.
-spec decode(primitive_type(), binary()) -> {primitive(), binary()}.
decode(boolean, Bin) ->
  <<Value:8/?INT, Rest/binary>> = Bin,
  {Value =/= 0, Rest};
decode(int8, Bin) ->
  <<Value:8/?INT, Rest/binary>> = Bin,
  {Value, Rest};
decode(int16, Bin) ->
  <<Value:16/?INT, Rest/binary>> = Bin,
  {Value, Rest};
decode(int32, Bin) ->
  <<Value:32/?INT, Rest/binary>> = Bin,
  {Value, Rest};
decode(int64, Bin) ->
  <<Value:64/?INT, Rest/binary>> = Bin,
  {Value, Rest};
decode(string, Bin) ->
  <<Size:16/?INT, Rest/binary>> = Bin,
  copy_bytes(Size, Rest);
decode(bytes, Bin) ->
  <<Size:32/?INT, Rest/binary>> = Bin,
  copy_bytes(Size, Rest);
decode(nullable_string, Bin) ->
  decode(string, Bin);
decode(records, Bin) ->
  decode(bytes, Bin).

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

%% @private
-spec encode_messages(kv_list(), compress_option()) -> iodata().
encode_messages(KvList, Compression) ->
  Encoded = encode_messages(KvList),
  case Compression =:= no_compression of
    true  -> Encoded;
    false -> compress(Compression, Encoded)
  end.

%% @private
-spec encode_messages(kv_list()) -> iodata().
encode_messages([]) -> [];
encode_messages([{_K, [Msg | _] = Nested} | Rest]) when is_tuple(Msg) ->
  [ encode_messages(Nested)
  | encode_messages(Rest)
  ];
encode_messages([{K, V} | Rest]) ->
  [ encode_message(?KPRO_ATTRIBUTES, ?NO_TIMESTAMP, K, V)
  | encode_messages(Rest)];
encode_messages([{T, K, V} | Rest]) ->
  [encode_message(?KPRO_ATTRIBUTES, T, K, V) | encode_messages(Rest)].

%% @private
-spec encode_message(byte(), msg_ts(), key(), value()) -> iodata().
encode_message(Attributes, T, Key, Value) ->
  {MagicByte, CreateTs} =
    case T of
      ?NO_TIMESTAMP -> {?KPRO_MAGIC_0, <<>>};
      _             -> {?KPRO_MAGIC_1, encode(int64, T)}
    end,
  Body = [ encode(int8, MagicByte)
         , encode(int8, Attributes)
         , CreateTs
         , encode(bytes, Key)
         , encode(bytes, Value)
         ],
  Crc  = encode(int32, erlang:crc32(Body)),
  Size = data_size([Crc, Body]),
  [encode(int64, _Offset = -1),
   encode(int32, Size),
   Crc, Body
  ].

%% @private Decode byte stream of kafka messages.
%% Messages are returned in reversed order
%% @end
-spec decode_message_stream(binary(), [decoded_message()]) ->
        [decoded_message()].
decode_message_stream(<<>>, Acc) ->
  %% NOTE: called recursively, do NOT reverse Acc here
  Acc;
decode_message_stream(Bin, Acc) ->
  {NewAcc, Rest} = decode_message(Bin, Acc),
  decode_message_stream(Rest, NewAcc).

%% @private
-spec decode_message(binary(), [decoded_message()]) ->
        {[decoded_message()], binary()}.
decode_message(<<>>, Acc) -> {Acc, <<>>};
decode_message(<<Offset:64/?INT, MsgSize:32/?INT, T/binary>>, Acc) ->
  case size(T) < MsgSize of
    true ->
      {[?incomplete_message(MsgSize + 12) | Acc], <<>>};
    false ->
      <<Body:MsgSize/binary, Rest/binary>> = T,
      {do_decode_message(Offset, Body, Acc), Rest}
  end;
decode_message(_, Acc) ->
  %% need to fetch at least 12 bytes to know the message size
  {[?incomplete_message(12) | Acc], <<>>}.

%% @private Comment is copied from:
%% core/src/main/scala/kafka/message/Message.scala
%%
%% The format of an N byte message is the following:
%% 1. 4 byte CRC32 of the message
%% 2. 1 byte "magic" identifier to allow format changes, value is 0 or 1
%% 3. 1 byte "attributes" identifier to allow annotations on the message
%%           independent of the version
%%    bit 0 ~ 2 : Compression codec.
%%      0 : no compression
%%      1 : gzip
%%      2 : snappy
%%      3 : lz4
%%    bit 3 : Timestamp type
%%      0 : create time
%%      1 : log append time
%%    bit 4 ~ 7 : reserved
%% 4. (Optional) 8 byte timestamp only if "magic" identifier is greater than 0
%% 5. 4 byte key length, containing length K
%% 6. K byte key
%% 7. 4 byte payload length, containing length V
%% 8. V byte payload
%% @end
-spec do_decode_message(offset(), binary(), [message()]) -> [message()].
do_decode_message(Offset, <<Crc:32/unsigned-integer, Body/binary>>, Acc) ->
  case Crc =:= erlang:crc32(Body) of
    true  -> ok;
    false -> erlang:error({corrupted_message, Offset, Body})
  end,
  {MagicByte, Rest0} = decode(int8, Body),
  {Attributes, Rest1} = decode(int8, Rest0),
  Compression = decode_compression_codec(Attributes),
  TsType = decode_timestamp_type(MagicByte, Attributes),
  {Ts, Rest2} =
    case TsType of
      undefined -> {undefined, Rest1};
      _         -> decode(int64, Rest1)
    end,
  {Key, Rest} = decode(bytes, Rest2),
  {Value, <<>>} = decode(bytes, Rest),
  case Compression =:= no_compression of
    true ->
      Msg = #kafka_message{ offset = Offset
                          , value = Value
                          , key = Key
                          , ts = Ts
                          , ts_type = TsType
                          , crc = Crc
                          , magic_byte = MagicByte
                          , attributes = Attributes
                          },
      [Msg | Acc];
    false ->
      Bin = decompress(Compression, Value),
      decode_message_stream(Bin, Acc)
  end.

%% @private
-spec decode_compression_codec(byte()) -> compress_option().
decode_compression_codec(A) when ?KPRO_IS_GZIP_ATTR(A) -> gzip;
decode_compression_codec(A) when ?KPRO_IS_SNAPPY_ATTR(A) -> snappy;
decode_compression_codec(A) when ?KPRO_IS_LZ4_ATTR(A) -> lz4;
decode_compression_codec(_) -> no_compression.

%% @private
-spec decode_timestamp_type(byte(), byte()) -> timestamp_type().
decode_timestamp_type(0, _) -> undefined;
decode_timestamp_type(_, A) when ?KPRO_IS_CREATE_TS(A) -> create;
decode_timestamp_type(_, A) when ?KPRO_IS_APPEND_TS(A) -> append.

%% @private
-spec compress(compress_option(), iodata()) -> iodata().
compress(Method, IoData) ->
  Attributes = case Method of
                 gzip   -> ?KPRO_COMPRESS_GZIP;
                 snappy -> ?KPRO_COMPRESS_SNAPPY;
                 lz4    -> ?KPRO_COMPRESS_LZ4
               end,
  Key = <<>>,
  Value = do_compress(Method, IoData),
  encode_message(Attributes, ?NO_TIMESTAMP, Key, Value).

%% @private TODO: lz4 compression.
-spec do_compress(compress_option(), iodata()) -> iodata().
do_compress(gzip, IoData) ->
  zlib:gzip(IoData);
do_compress(snappy, IoData) ->
  snappy_compress(IoData).

%% @private
-spec decode_response(binary(), [rsp()]) -> {[rsp()], binary()}.
decode_response(Bin, Acc) ->
  case do_decode_response(Bin) of
    {incomplete, Rest} ->
      {lists:reverse(Acc), Rest};
    {Response, Rest} ->
      decode_response(Rest, [Response | Acc])
  end.

%% @private Decode responses received from kafka broker.
%% {incomplete, TheOriginalBinary} is returned if this is not a complete packet.
%% @end
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

%% @private
-spec decompress(compress_option(), binary()) -> binary().
decompress(Method, Value) ->
  case Method of
    gzip -> zlib:gunzip(Value);
    snappy -> java_snappy_unpack(Value);
    lz4 -> lz4_unpack(Value)
  end.

%% @private
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

%% @private Encode embedded bytes.
-spec enc_embedded(stack(), field_value()) -> field_value().
enc_embedded([protocol_metadata | _] = Stack, Value) ->
  Schema = get_schema(?PRELUDE, cg_protocol_metadata, 0),
  bin(enc_struct(Schema, Value, Stack));
enc_embedded([member_assignment | _] = Stack, Value) ->
  Schema = get_schema(?PRELUDE, cg_memeber_assignment, 0),
  bin(enc_struct(Schema, Value, Stack));
enc_embedded(_Stack, Value) -> Value.

%% @private A struct field should have one of below types:
%% 1. An array of any
%% 2. Another struct
%% 3. A user define decoder
%% 4. A primitive
%% @end
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

%% @private
-spec dec_array_elements(count(), schema(), stack(), binary(), Acc) ->
        {Acc, binary()} when Acc :: [field_value()].
dec_array_elements(0, _Schema, _Stack, Bin, Acc) ->
  {lists:reverse(Acc), Bin};
dec_array_elements(N, Schema, Stack, Bin, Acc) ->
  {Element, Rest} = dec_struct_field(Schema, Stack, Bin),
  dec_array_elements(N-1, Schema, Stack, Rest, [Element | Acc]).

%% @private Translate error codes; Dig up embedded bytes.
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

%% @private Decode struct, assume no tail bytes.
-spec dec_struct_clean(schema(), stack(), binary()) -> struct().
dec_struct_clean(Schema, Stack, Bin) ->
  {Fields, <<>>} = dec_struct(Schema, [], Stack, Bin),
  Fields.

%% @private
-spec copy_bytes(-1 | count(), binary()) -> {undefined | binary(), binary()}.
copy_bytes(-1, Bin) ->
  {undefined, Bin};
copy_bytes(Size, Bin) ->
  <<Bytes:Size/binary, Rest/binary>> = Bin,
  {binary:copy(Bytes), Rest}.

-define(IS_BYTE(I), (I>=0 andalso I<256)).

%% @private
-spec data_size(iodata()) -> count().
data_size(IoData) ->
  data_size(IoData, 0).

%% @private
-spec data_size(iodata(), count()) -> count().
data_size([], Size) -> Size;
data_size(<<>>, Size) -> Size;
data_size(I, Size) when ?IS_BYTE(I) -> Size + 1;
data_size(B, Size) when is_binary(B) -> Size + size(B);
data_size([H | T], Size0) ->
  Size1 = data_size(H, Size0),
  data_size(T, Size1).

%% @private snappy-java adds its own header (SnappyCodec)
%% which is not compatible with the official Snappy
%% implementation.
%% 8: magic, 4: version, 4: compatible
%% followed by any number of chunks:
%%    4: length
%%  ...: snappy-compressed data.
%% @end
java_snappy_unpack(Bin) ->
  <<_:16/binary, Chunks/binary>> = Bin,
  java_snappy_unpack_chunks(Chunks, []).

java_snappy_unpack_chunks(<<>>, Acc) ->
  bin(Acc);
java_snappy_unpack_chunks(Chunks, Acc) ->
  <<Len:32/unsigned-integer, Rest/binary>> = Chunks,
  case Len =:= 0 of
    true ->
      Rest =:= <<>> orelse erlang:error({Len, Rest}), %% assert
      Acc;
    false ->
      <<Data:Len/binary, Tail/binary>> = Rest,
      Decompressed = snappy_decompress(Data),
      java_snappy_unpack_chunks(Tail, [Acc, Decompressed])
  end.

%% @private
-spec lz4_unpack(_) -> no_return().
lz4_unpack(_) -> erlang:error({no_impl, lz4}).

%% @private
snappy_compress(IoData) ->
  {ok, Compressed} = snappyer:compress(IoData),
  Compressed.

%% @private
snappy_decompress(BinData) ->
  {ok, Decompressed} = snappyer:decompress(BinData),
  Decompressed.

%% @private
-spec bin(iodata()) -> binary().
bin(X) -> iolist_to_binary(X).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
