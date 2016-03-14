%%%
%%%   Copyright (c) 2014-2016, Klarna AB
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

%% help apis to constricut kpro_Xxx structures.
-export([ fetch_request/6
        , offset_request/4
        , produce_request/5
        ]).

-export([ decode_response/1
        , encode_request/1
        , encode_request/3
        , next_corr_id/1
        ]).

%% exported for internal use
-export([ decode/2
        , decode_fields/3
        , encode/1
        ]).

-include("kpro.hrl").

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


%% @doc Help function to construct a #kpro_ProduceRequest{} for
%% messages targeting one single topic-partition.
%% @end
-spec produce_request(topic(), partition(), [{binary(), binary()}],
                      integer(), non_neg_integer()) ->
                         kpro_ProduceRequest().
produce_request(Topic, Partition, KafkaKvList, RequiredAcks, AckTimeout) ->
  Messages =
    lists:map(fun({K, V}) ->
                  #kpro_Message{ magicByte  = ?KPRO_MAGIC_BYTE
                               , attributes = ?KPRO_ATTRIBUTES
                               , key        = K
                               , value      = V
                               }
              end, KafkaKvList),
  PartitionMsgSet =
    #kpro_PartitionMessageSet{ partition = Partition
                             , message_L = Messages
                             },
  TopicMessageSet =
    #kpro_TopicMessageSet{ topicName             = Topic
                         , partitionMessageSet_L = [PartitionMsgSet]
                         },
  #kpro_ProduceRequest{ requiredAcks      = RequiredAcks
                      , timeout           = AckTimeout
                      , topicMessageSet_L = [TopicMessageSet]
                      }.

%% @doc Get the next correlation ID.
-spec next_corr_id(corr_id()) -> corr_id().
next_corr_id(?MAX_CORR_ID) -> 0;
next_corr_id(CorrId)       -> CorrId + 1.

%% @doc Parse binary stream received from kafka broker.
%%      Return a list of kpro_Response() and the remaining bytes.
%% @end
-spec decode_response(binary()) -> {kpro_Response(), binary()}.
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
-spec encode_request(client_id(), corr_id(), RequestMessage) -> iodata()
        when RequestMessage:: kpro_ProduceRequest()
                            | kpro_FetchRequest()
                            | kpro_OffsetRequest()
                            | kpro_MetadataRequest()
                            | kpro_OffsetCommitRequestV0()
                            | kpro_OffsetCommitRequestV1()
                            | kpro_OffsetCommitRequestV2()
                            | kpro_OffsetFetchRequest()
                            | kpro_GroupCoordinatorRequest()
                            | kpro_JoinGroupRequest()
                            | kpro_HeartbeatRequest()
                            | kpro_LeaveGroupRequest()
                            | kpro_SyncGroupRequest()
                            | kpro_DescribeGroupsRequest()
                            | kpro_ListGroupsRequest().
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
  ApiVersion = case ApiVersion0 =:= undefined of
                  true  -> get_api_version(RequestMessage);
                  false -> ApiVersion0
               end,
  IoData =
    [ encode({int16, ApiKey})
    , encode({int16, ApiVersion})
    , encode({int32, CorrId})
    , encode({string, ClientId})
    , encode(RequestMessage)
    ],
  Size = data_size(IoData),
  [encode({int32, Size}), IoData].

%%%_* Internal functions =======================================================

get_api_version(#kpro_OffsetCommitRequestV1{}) -> 1;
get_api_version(#kpro_OffsetCommitRequestV2{}) -> 2;
get_api_version(#kpro_OffsetFetchRequest{})    -> 1;
get_api_version(_)                             -> 0.

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
  MessageSet = [encode(M) || M <- R#kpro_PartitionMessageSet.message_L],
  Size = data_size(MessageSet),
  [encode({int32, R#kpro_PartitionMessageSet.partition}),
   encode({int32, Size}),
   MessageSet
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
  Body =
    [encode({int8, MagicByte}),
     encode({int8, Attributes}),
     encode({bytes, R#kpro_Message.key}),
     encode({bytes, R#kpro_Message.value})],
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
    MsgsBin:MessageSetSize/binary,
    Rest/binary>> = Bin,
  %% messages in messageset are not array elements, but stream
  Messages = decode_message_stream(MsgsBin, []),
  PartitionMessages =
    #kpro_FetchResponsePartition
      { partition           = Partition
      , errorCode           = kpro_ErrorCode:decode(ErrorCode)
      , highWatermarkOffset = HighWmOffset
      , messageSetSize      = MessageSetSize
      , message_L           = Messages
      },
  {PartitionMessages, Rest};
decode(StructName, Bin) when is_atom(StructName) ->
  kpro_structs:decode(StructName, Bin).

decode_message_stream(<<>>, Acc) ->
  lists:reverse(Acc);
decode_message_stream(Bin, Acc) ->
  {Msg, Rest} =
    try decode(kpro_Message, Bin)
    catch error : {badmatch, _} ->
      {?incomplete_message, <<>>}
    end,
  decode_message_stream(Rest, [Msg | Acc]).

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

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
