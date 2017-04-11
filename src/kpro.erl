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

%% help apis to build some of most common kpro_Xxx structures.
-export([ fetch_request/6
        , offset_request/4
        , produce_request/5
        , produce_request/6
        ]).

-export([ decode_response/1
        , decode_message_set/1
        , encode_request/1
        , encode_request/3
        , next_corr_id/1
        , to_maps/1
        ]).

%% exported for caller defined schema
-export([ decode/2
        , encode/1
        ]).

%% exported for internal use
-export([ decode_fields/3
        ]).

-export_type([ int8/0
             , int16/0
             , int32/0
             , int64/0
             , str/0
             , bytes/0
             , records/0
             , api_key/0
             , error_code/0
             , client_id/0
             , topic/0
             , partition/0
             , offset/0
             , key/0
             , value/0
             , kafka_key/0
             , kafka_value/0
             , corr_id/0
             , incomplete_message/0
             ]).

-include("kpro.hrl").

-type int8()       :: -128..127.
-type int16()      :: -32768..32767.
-type int32()      :: -2147483648..2147483647.
-type int64()      :: -9223372036854775808..9223372036854775807.
-type str()        :: undefined | string() | binary().
-type bytes()      :: undefined | binary().
-type records()    :: undefined | binary().
-type api_key()    :: 0..17.
-type error_code() :: int16() | atom().

%% type re-define for readability
-type client_id() :: str().
-type corr_id()   :: int32().
-type topic()     :: str().
-type partition() :: int32().
-type offset()    :: int64().

-type key() :: undefined | iodata().
-type value() :: undefined | iodata() | [{key(), kv_list()}].
-type kv_list() :: [{key(), value()}].

-type kafka_key() :: key().
-type kafka_value() :: undefined | iodata() | [kpro_Message()].

-type incomplete_message() :: {?incomplete_message, int32()}.

-define(INT, signed-integer).

%% @doc Help function to contruct a #kpro_OffsetRequest{} for requests
%% against one single topic-partition.
%% @end
-spec offset_request(topic(), partition(), integer(), non_neg_integer()) ->
        kpro_OffsetRequest().
offset_request(Topic, Partition, Time, MaxNoOffsets) ->
  PartitionReq =
    #kpro_OffsetRequestPartition{ partition          = Partition
                                , time               = Time
                                , maxNumberOfOffsets = MaxNoOffsets
                                },
  TopicReq =
    #kpro_OffsetRequestTopic{ topicName                = Topic
                            , offsetRequestPartition_L = [PartitionReq]
                            },
  #kpro_OffsetRequest{ replicaId            = ?KPRO_REPLICA_ID
                     , offsetRequestTopic_L = [TopicReq]
                     }.

%% @doc Help function to construct a #kpro_FetchRequest{} against one signle
%% topic-partition.
%% @end
-spec fetch_request(topic(), partition(), offset(),
                    non_neg_integer(), non_neg_integer(), pos_integer()) ->
                      kpro_FetchRequest().
fetch_request(Topic, Partition, Offset, MaxWaitTime, MinBytes, MaxBytes) ->
  PerPartition =
    #kpro_FetchRequestPartition{ partition   = Partition
                               , fetchOffset = Offset
                               , maxBytes    = MaxBytes
                               },
  PerTopic =
    #kpro_FetchRequestTopic{ topicName               = Topic
                           , fetchRequestPartition_L = [PerPartition]
                           },
  #kpro_FetchRequest{ replicaId           = ?KPRO_REPLICA_ID
                    , maxWaitTime         = MaxWaitTime
                    , minBytes            = MinBytes
                    , fetchRequestTopic_L = [PerTopic]
                    }.


%% @equiv produce_request(Topic, Partition, KvList, RequiredAcks,
%%                        AckTimeout, no_compression)
%% @end
-spec produce_request(topic(), partition(), kv_list(),
                      integer(), non_neg_integer()) ->
                        kpro_ProduceRequest().
produce_request(Topic, Partition, KvList, RequiredAcks, AckTimeout) ->
  produce_request(Topic, Partition, KvList, RequiredAcks, AckTimeout,
                  no_compression).

%% @doc Help function to construct a #kpro_ProduceRequest{} for
%% messages targeting one single topic-partition.
%% @end
-spec produce_request(topic(), partition(), kv_list(),
                      integer(), non_neg_integer(),
                      kpro_compress_option()) -> kpro_ProduceRequest().
produce_request(Topic, Partition, KvList,
                RequiredAcks, AckTimeout, CompressOption) ->
  Messages = encode_messages(KvList, CompressOption),
  PartitionMsgSet =
    #kpro_PartitionMessageSet{ partition = Partition
                             , message_L = Messages
                             },
  TopicMessageSet =
    #kpro_TopicMessageSet{ topicName             = Topic
                         , partitionMessageSet_L = [PartitionMsgSet]
                         },
  %% Encode message set here right now.
  %% Instead of keeping a possibily very large array
  %% and passing it around processes
  %% e.g. in brod, the message set can be encoded in producer
  %% worker before sending it down to socket process
  MessageSetBin = iolist_to_binary(encode({array, [TopicMessageSet]})),
  #kpro_ProduceRequest{ requiredAcks      = RequiredAcks
                      , timeout           = AckTimeout
                      , topicMessageSet_L = {already_encoded, MessageSetBin}
                      }.

%% @doc Get the next correlation ID.
-spec next_corr_id(corr_id()) -> corr_id().
next_corr_id(?MAX_CORR_ID) -> 0;
next_corr_id(CorrId)       -> CorrId + 1.

%% @doc Parse binary stream received from kafka broker.
%%      Return a list of kpro_Response() and the remaining bytes.
%% @end
-spec decode_response(binary()) -> {[kpro_Response()], binary()}.
decode_response(Bin) ->
  decode_response(Bin, []).

decode_response(Bin, Acc) ->
  case do_decode_response(Bin) of
    {incomplete, Rest} ->
      {lists:reverse(Acc), Rest};
    {Response, Rest} ->
      decode_response(Rest, [Response | Acc])
  end.

%% @doc help function to encode kpro_XxxRequest into kafka wire format.
-spec encode_request(client_id(), corr_id(), kpro_RequestMessage()) -> iodata().
encode_request(ClientId, CorrId, Request) ->
  R = #kpro_Request{ correlationId  = CorrId
                   , clientId       = ClientId
                   , requestMessage = Request
                   },
  encode_request(R).

%% @doc Encode #kpro_Request{} records into kafka wire format.
-spec encode_request(kpro_Request()) -> iodata().
encode_request(#kpro_Request{ apiVersion     = ApiVersion0
                            , correlationId  = CorrId0
                            , clientId       = ClientId
                            , requestMessage = RequestMessage
                            }) ->
  true = (CorrId0 =< ?MAX_CORR_ID), %% assert
  ApiKey = req_to_api_key(RequestMessage),
  CorrId = (ApiKey bsl ?CORR_ID_BITS) bor CorrId0,
  ApiVersion = get_api_version(ApiVersion0, RequestMessage),
  IoData =
    [ encode({int16, ApiKey})
    , encode({int16, ApiVersion})
    , encode({int32, CorrId})
    , encode({string, ClientId})
    , encode(RequestMessage)
    ],
  Size = data_size(IoData),
  [encode({int32, Size}), IoData].

%% @doc Convert decoded records to maps.
to_maps(R) when is_tuple(R) ->
  RecordName = element(1, R),
  case kpro_records:fields(RecordName) of
    FieldNames when is_list(FieldNames) ->
      "kpro_" ++ Tag = atom_to_list(RecordName),
      Values = [to_maps(V) || V <- tl(tuple_to_list(R))],
      KVL = [{kpro_tag, Tag} | lists:zip(FieldNames, Values)],
      do_to_maps(KVL);
    false ->
      R
  end;
to_maps(L) when is_list(L) ->
  [to_maps(I) || I <- L];
to_maps(Other) ->
  Other.

%%%_* Internal functions =======================================================

-ifndef(NO_MAPS).
do_to_maps(KVL) -> maps:from_list(KVL).
-else.
do_to_maps(KVL) -> KVL.
-endif.

-spec encode_messages(kv_list(), kpro_compress_option()) -> iodata().
encode_messages(KvList, Compression) ->
  Encoded = encode_messages(KvList),
  case Compression =:= no_compression of
    true  -> Encoded;
    false -> compress(Compression, Encoded)
  end.

encode_messages([]) -> [];
encode_messages([{_K, [{_NestedK, _NestedV} | _] = NestedKvList} | KvList]) ->
  [ encode_messages(NestedKvList)
  | encode_messages(KvList)
  ];
encode_messages([{K, V} | KvList]) ->
  Msg = #kpro_Message{ attributes = ?KPRO_COMPRESS_NONE
                     , key        = K
                     , value      = V
                     },
  [encode(Msg) | encode_messages(KvList)].

compress(Method, IoData) ->
  Attributes = case Method of
                 gzip   -> ?KPRO_COMPRESS_GZIP;
                 snappy -> ?KPRO_COMPRESS_SNAPPY;
                 lz4    -> ?KPRO_COMPRESS_LZ4
               end,
  Msg = #kpro_Message{ attributes = Attributes
                     , key        = <<>>
                     , value      = do_compress(Method, IoData)
                     },
  [encode(Msg)].


%% TODO: lz4 compression
-spec do_compress(kpro_compress_option(), iodata()) -> iodata().
do_compress(gzip, IoData) ->
  zlib:gzip(IoData);
do_compress(snappy, IoData) ->
  snappy_compress(IoData).

-spec get_api_version(int16() | undefined, kpro_RequestMessage()) -> int16().
get_api_version(V, _Msg) when is_integer(V) -> V;
get_api_version(undefined, Msg)             -> api_version(Msg).

-spec api_version(kpro_RequestMessage()) -> int16().
api_version(#kpro_OffsetCommitRequestV1{}) -> 1;
api_version(#kpro_OffsetCommitRequestV2{}) -> 2;
api_version(#kpro_OffsetFetchRequest{})    -> 1;
api_version(_Default)                      -> 0.

%% @private Decode responses received from kafka broker.
%% {incomplete, TheOriginalBinary} is returned if this is not a complete packet.
%% @end
-spec do_decode_response(binary()) -> {incomplete | #kpro_Response{}, binary()}.
do_decode_response(<<Size:32/?INT, Bin/binary>>) when size(Bin) >= Size ->
  <<I:32/integer, Rest0/binary>> = Bin,
  ApiKey = I bsr ?CORR_ID_BITS,
  CorrId = I band ?MAX_CORR_ID,
  Type = ?API_KEY_TO_RSP(ApiKey),
  {Message, Rest} =
    try
      decode(Type, Rest0)
    catch error : E ->
      Context = [ {api_key, ApiKey}
                , {corr_id, CorrId}
                , {payload, Rest0}
                ],
      erlang:error({E, Context, erlang:get_stacktrace()})
    end,
  Result =
    #kpro_Response{ correlationId   = CorrId
                  , responseMessage = Message
                  },
  {Result, Rest};
do_decode_response( Bin) ->
  {incomplete, Bin}.

%% @doc The messageset is not decoded upon receiving (in socket process)
%% Pass the message set as binary to the consumer process and decode there
%% @end
decode_message_set(MessageSetBin) when is_binary(MessageSetBin) ->
  lists:reverse(decode_message_stream(MessageSetBin, [])).

%% @hidden
encode({Fun, Data}) when is_function(Fun, 1) -> Fun(Data);
encode({_, {already_encoded, Data}})  -> Data;
encode({boolean, true}) -> <<1:8/?INT>>;
encode({boolean, false}) -> <<0:8/?INT>>;
encode({int8,  I}) when is_integer(I) -> <<I:8/?INT>>;
encode({int16, I}) when is_integer(I) -> <<I:16/?INT>>;
encode({int32, I}) when is_integer(I) -> <<I:32/?INT>>;
encode({int64, I}) when is_integer(I) -> <<I:64/?INT>>;
encode({string, undefined}) ->
  <<-1:16/?INT>>;
encode({string, L}) when is_list(L) ->
  encode({string, iolist_to_binary(L)});
encode({string, <<>>}) ->
  <<0:16/?INT>>;
encode({string, B}) when is_binary(B) ->
  Length = size(B),
  <<Length:16/?INT, B/binary>>;
encode({bytes, undefined}) ->
  <<-1:32/?INT>>;
encode({bytes, B}) when is_binary(B) orelse is_list(B) ->
  Size = data_size(B),
  case Size =:= 0 of
    true  -> <<-1:32/?INT>>;
    false -> [<<Size:32/?INT>>, B]
  end;
encode({{array, T}, L}) when is_list(L) ->
  true = ?IS_KAFKA_PRIMITIVE(T), %% assert
  Length = length(L),
  [<<Length:32/?INT>>, [encode({T, I}) || I <- L]];
encode({array, L}) when is_list(L) ->
  Length = length(L),
  [<<Length:32/?INT>>, [encode(I) || I <- L]];
encode(#kpro_PartitionMessageSet{} = R) ->
  %% messages in messageset is a stream, not an array
  EncodedMessages = R#kpro_PartitionMessageSet.message_L,
  Size = data_size(EncodedMessages),
  [encode({int32, R#kpro_PartitionMessageSet.partition}),
   encode({int32, Size}),
   EncodedMessages
  ];
encode(#kpro_Message{} = R) ->
  MagicByte = case R#kpro_Message.magicByte of
                undefined            -> ?KPRO_MAGIC_BYTE;
                M when is_integer(M) -> M
              end,
  Attributes = case R#kpro_Message.attributes of
                 undefined            -> ?KPRO_ATTRIBUTES;
                 A when is_integer(A) -> A
               end,
  Body = [ encode({int8, MagicByte})
         , encode({int8, Attributes})
         , encode({bytes, R#kpro_Message.key})
         , encode({bytes, R#kpro_Message.value})
         ],
  Crc  = encode({int32, erlang:crc32(Body)}),
  Size = data_size([Crc, Body]),
  [encode({int64, -1}),
   encode({int32, Size}),
   Crc, Body
  ];
encode(#kpro_GroupAssignment{memberAssignment = MA} = GA) ->
  case MA of
    #kpro_ConsumerGroupMemberAssignment{} ->
      %% member assignment is an embeded 'bytes' blob
      Bytes = encode(MA),
      kpro_structs:encode(GA#kpro_GroupAssignment{memberAssignment = Bytes});
    _IoData ->
      %% the higher level user may have it encoded already
      kpro_structs:encode(GA)
  end;
encode(#kpro_GroupProtocol{protocolMetadata = PM} = GP) ->
  case PM of
    #kpro_ConsumerGroupProtocolMetadata{} ->
      %% Group protocol metadata is an embeded 'bytes' blob
      Bytes = encode(PM),
      kpro_structs:encode(GP#kpro_GroupProtocol{protocolMetadata = Bytes});
    _IoData ->
      %% the higher level user may have it encoded already
      kpro_structs:encode(GP)
  end;
encode(Struct) when is_tuple(Struct) ->
  kpro_structs:encode(Struct).

%% @hidden
decode(Fun, Bin) when is_function(Fun, 1) ->
  Fun(Bin);
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
decode({array, Type}, Bin) ->
  <<Length:32/?INT, Rest/binary>> = Bin,
  decode_array_elements(Length, Type, Rest, _Acc = []);
decode(kpro_FetchResponsePartition, Bin) ->
  %% special treat since message sets may get partially delivered
  <<Partition:32/?INT,
    ErrorCode:16/?INT,
    HighWmOffset:64/?INT,
    MessageSetSize:32/?INT,
    MessageSetBin:MessageSetSize/binary,
    Rest/binary>> = Bin,
  PartitionMessages =
    #kpro_FetchResponsePartition
      { partition           = Partition
      , errorCode           = kpro_ErrorCode:decode(ErrorCode)
      , highWatermarkOffset = HighWmOffset
      , messageSetSize      = MessageSetSize
      , message_L           = MessageSetBin
      },
  {PartitionMessages, Rest};
decode(StructName, Bin) when is_atom(StructName) ->
  kpro_structs:decode(StructName, Bin).

%% @private
-spec decode_message(binary()) ->
        {kpro_Message() | incomplete_message(), binary()}.
decode_message(<<_Offset:64/?INT, MsgSize:32/?INT, T/binary>> = Bin) ->
  case size(T) < MsgSize of
    true  -> {{?incomplete_message, MsgSize + 12}, <<>>};
    false -> decode(kpro_Message, Bin)
  end;
decode_message(_) ->
  %% need to fetch at least 12 bytes to know the message size
  {{?incomplete_message, 12}, <<>>}.

%% @private Decode byte stream of kafka messages.
%% Return messages in reversed order.
%% @end
-spec decode_message_stream(binary(), Decoded) -> Decoded
        when Decoded :: [kpro_Message() | incomplete_message()].
decode_message_stream(<<>>, Acc) ->
  %% Do not reverse here!
  %% as the input is recursive when compressed
  Acc;
decode_message_stream(Bin, Acc) ->
  {Msg, Rest} = decode_message(Bin),
  NewAcc =
    case Msg of
      #kpro_Message{attributes = Attr} = Msg when ?KPRO_IS_GZIP_ATTR(Attr) ->
        decode_message_stream(zlib:gunzip(Msg#kpro_Message.value), Acc);
      #kpro_Message{attributes = Attr} = Msg when ?KPRO_IS_SNAPPY_ATTR(Attr) ->
        decode_message_stream(java_snappy_unpack(Msg#kpro_Message.value), Acc);
      #kpro_Message{attributes = Attr} = Msg when ?KPRO_IS_LZ4_ATTR(Attr) ->
        decode_message_stream(lz4_unpack(Msg#kpro_Message.value), Acc);
      _Else ->
        [Msg | Acc]
    end,
  decode_message_stream(Rest, NewAcc).

decode_fields(RecordName, Fields, Bin) ->
  {FieldValues, BinRest} = do_decode_fields(RecordName, Fields, Bin, _Acc = []),
  %% make the record.
  {list_to_tuple([RecordName | FieldValues]), BinRest}.

do_decode_fields(_RecordName, _Fields = [], Bin, Acc) ->
  {lists:reverse(Acc), Bin};
do_decode_fields(RecordName, [{FieldName, FieldType} | Rest], Bin, Acc) ->
  {FieldValue0, BinRest} = decode(FieldType, Bin),
  FieldValue = maybe_translate(RecordName, FieldName, FieldValue0),
  do_decode_fields(RecordName, Rest, BinRest, [FieldValue | Acc]).

%% Translate specific values to human readable format.
%% or decode nested structure in embeded bytes
%% e.g. error codes.
maybe_translate(_RecordName, errorCode, Code) ->
  kpro_ErrorCode:decode(Code);
maybe_translate(kpro_GroupMemberMetadata, protocolMetadata, Bin) ->
  maybe_decode_consumer_group_member_metadata(Bin);
maybe_translate(_, memberAssignment, Bin) ->
  maybe_decode_consumer_group_member_assignment(Bin);
maybe_translate(_RecordName, _FieldName, RawValue) ->
  RawValue.

maybe_decode_consumer_group_member_metadata(Bin) ->
  try
    {GroupMemberMetadata, <<>>} =
      decode(kpro_ConsumerGroupProtocolMetadata, Bin),
    GroupMemberMetadata
  catch error : {badmatch, _} ->
    %% in case not consumer group protocol
    %% leave it for the higher level user to decode
    Bin
  end.

maybe_decode_consumer_group_member_assignment(Bin) ->
  try
    {MemberAssignment, <<>>} = decode(kpro_ConsumerGroupMemberAssignment, Bin),
    MemberAssignment
  catch error : {badmatch, _} ->
    %% in case not consumer group protocol
    %% leave it for the higher level user to decode
    Bin
  end.

copy_bytes(-1, Bin) ->
  {undefined, Bin};
copy_bytes(Size, Bin) ->
  <<Bytes:Size/binary, Rest/binary>> = Bin,
  {binary:copy(Bytes), Rest}.

decode_array_elements(0, _Type, Bin, Acc) ->
  {lists:reverse(Acc), Bin};
decode_array_elements(N, Type, Bin, Acc) ->
  {Element, Rest} = decode(Type, Bin),
  decode_array_elements(N-1, Type, Rest, [Element | Acc]).

-define(IS_BYTE(I), (I>=0 andalso I<256)).

data_size(IoData) ->
  data_size(IoData, 0).

data_size([], Size) -> Size;
data_size(<<>>, Size) -> Size;
data_size(I, Size) when ?IS_BYTE(I) -> Size + 1;
data_size(B, Size) when is_binary(B) -> Size + size(B);
data_size([H | T], Size0) ->
  Size1 = data_size(H, Size0),
  data_size(T, Size1).

-spec req_to_api_key(atom()) -> integer().
req_to_api_key(Req) when is_tuple(Req) ->
  req_to_api_key(element(1, Req));
req_to_api_key(Req) when is_atom(Req) ->
  ?REQ_TO_API_KEY(Req).

%% @private snappy-java adds its own header (SnappyCodec)
%% which is not compatible with the official Snappy
%% implementation.
%% 8: magic, 4: version, 4: compatible
%% followed by any number of chunks:
%%    4: length
%%  ...: snappy-compressed data.
java_snappy_unpack(Bin) ->
  <<_:16/binary, Chunks/binary>> = Bin,
  java_snappy_unpack_chunks(Chunks, []).

java_snappy_unpack_chunks(<<>>, Acc) ->
  iolist_to_binary(Acc);
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

lz4_unpack(_) -> erlang:error({no_impl, lz4}).

-ifndef(SNAPPY_DISABLED).

snappy_compress(IoData) ->
  {ok, Compressed} = snappyer:compress(IoData),
  Compressed.

snappy_decompress(BinData) ->
  {ok, Decompressed} = snappyer:decompress(BinData),
  Decompressed.

-else.

snappy_compress(_IoData) ->
  erlang:error(kafka_protocol_no_snappy).

snappy_decompress(_BinData) ->
  erlang:error(kafka_protocol_no_snappy).

-endif.


%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
