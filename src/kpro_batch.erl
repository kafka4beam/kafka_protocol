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

-module(kpro_batch).

-export([ decode/1
        , encode/3
        , encode_tx/4
        , is_control/1
        ]).

-include("kpro_private.hrl").

-type magic() :: kpro:magic().
-type message() :: kpro:message().
-type ts_type() :: kpro:timestamp_type().
-type msg_ts() :: kpro:msg_ts().
-type msg_input() :: kpro:msg_input().
-type seqno() :: kpro:seqno().
-type txn_ctx() :: kpro:txn_ctx().
-type compress_option() :: kpro:compress_option().
-type batch_input() :: kpro:batch_input().
-type offset() :: kpro:offset().
-type headers() :: kpro:headers().
-type batch_meta() :: kpro:batch_meta().
-define(NO_META, ?KPRO_NO_BATCH_META).

%% @doc Encode a list of batch inputs into byte stream.
-spec encode(magic(), batch_input(), compress_option()) -> binary().
encode(_MagicVsn = 2, Batch, Compression) ->
  FirstSequence = -1,
  NonTxn = #{ producer_id => -1
            , producer_epoch => -1
            },
  iolist_to_binary(encode_tx(Batch, Compression, FirstSequence, NonTxn));
encode(MagicVsn, Batch, Compression) ->
  iolist_to_binary(kpro_batch_v01:encode(MagicVsn, Batch, Compression)).

%% @doc Encode a batch of magic version 2.
% RecordBatch =>
%   FirstOffset => int64
%   Length => int32
%   PartitionLeaderEpoch => int32 # client set whatever
%   Magic => int8 # The 17th byte as in v0 and v1
%   CRC => int32
%   Attributes => int16
%   LastOffsetDelta => int32
%   FirstTimestamp => int64
%   MaxTimestamp => int64
%   ProducerId => int64
%   ProducerEpoch => int16
%   FirstSequence => int32
%   Records => [Record]
-spec encode_tx(batch_input(), compress_option(), seqno(), txn_ctx()) ->
        iodata().
encode_tx([FirstMsg | _] = Batch, Compression, FirstSequence,
          #{ producer_id := ProducerId
           , producer_epoch := ProducerEpoch
           }) ->
  IsTxn = is_integer(ProducerId) andalso ProducerId >= 0,
  FirstTimestamp =
    case maps:get(ts, FirstMsg, false) of
      false -> kpro_lib:now_ts();
      Ts -> Ts
    end,
  EncodedBatch = encode_batch(Compression, FirstTimestamp, Batch),
  EncodedAttributes = encode_attributes(Compression, IsTxn),
  PartitionLeaderEpoch = -1, % producer can set whatever
  FirstOffset = 0, % always 0
  Magic = 2, % always 2
  {Count, MaxTimestamp} = scan_max_ts(1, FirstTimestamp, tl(Batch)),
  LastOffsetDelta = Count - 1, % always count - 1 for producer
  Body0 =
    [ EncodedAttributes           % {Attributes0,     T1} = dec(int16, T0),
    , enc(int32, LastOffsetDelta) % {LastOffsetDelta, T2} = dec(int32, T1),
    , enc(int64, FirstTimestamp)  % {FirstTimestamp,  T3} = dec(int64, T2),
    , enc(int64, MaxTimestamp)    % {MaxTimestamp,    T4} = dec(int64, T3),
    , enc(int64, ProducerId)      % {ProducerId,      T5} = dec(int64, T4),
    , enc(int16, ProducerEpoch)   % {ProducerEpoch,   T6} = dec(int16, T5),
    , enc(int32, FirstSequence)   % {FirstSequence,   T7} = dec(int32, T6),
    , enc(int32, Count)           % {Count,           T8} = dec(int32, T7),
    , EncodedBatch
    ],
  Body1 = iolist_to_binary(Body0),
  CRC = crc32cer:nif(Body1),
  Body =
    [ enc(int32, PartitionLeaderEpoch)
    , enc(int8,  Magic)
    , enc(int32, CRC)
    , Body1
    ],
  Size = kpro_lib:data_size(Body),
  [ enc(int64, FirstOffset)
  , enc(int32, Size)
  | Body
  ].

%% @doc Decode received message-set into a batch list.
%% Ensured by `kpro:decode_batches/1', the input binary should contain
%% at least one mssage.
-spec decode(binary()) -> [{batch_meta(), [message()]}].
decode(Bin) ->
  decode(Bin, _Acc = []).

%% @doc Return true if it is a control batch.
-spec is_control(batch_meta()) -> boolean().
is_control(?NO_META) -> false;
is_control(#{is_control := Is}) -> Is.

%%%_* Internals ================================================================

-spec decode(binary(), Acc) -> Acc when Acc :: [{batch_meta(), [message()]}].
decode(<<Offset:64, L:32, Body:L/binary, Rest/binary>>, Acc) ->
  <<_:32, Magic:8, _:32, _/binary>> = Body,
  {Meta, MsgsReversed} =
    case Magic < 2 of
      true  -> {?NO_META, kpro_batch_v01:decode(Offset, Body)};
      false -> do_decode(Offset, Body)
    end,
  NewAcc =
    case Acc of
      [{?NO_META, MsgsReversed0} | Acc0] ->
        %% merge magic v0 batches
        [{?NO_META, MsgsReversed ++ MsgsReversed0} | Acc0];
      _ ->
        [{Meta, MsgsReversed} | Acc]
    end,
  decode(Rest, NewAcc);
decode(_IncompleteTail, Acc) ->
  lists:reverse(lists:map(fun({Meta, MsgsReversed}) ->
                              {Meta, lists:reverse(MsgsReversed)}
                          end, Acc)).

-spec scan_max_ts(pos_integer(), msg_ts(), batch_input()) ->
        {pos_integer(), msg_ts()}.
scan_max_ts(Count, MaxTs, []) -> {Count, MaxTs};
scan_max_ts(Count, MaxTs0, [#{ts := Ts} | Rest]) ->
  MaxTs = max(MaxTs0, Ts),
  scan_max_ts(Count + 1, MaxTs, Rest);
scan_max_ts(Count, MaxTs, [#{} | Rest]) ->
  scan_max_ts(Count + 1, MaxTs, Rest).

-spec encode_batch(compress_option(), msg_ts(), [msg_input()]) -> iodata().
encode_batch(Compression, TsBase, Batch) ->
  Encoded0 = enc_records(_Offset = 0, TsBase, Batch),
  Encoded = kpro_compress:compress(Compression, Encoded0),
  Encoded.

-spec enc_records(offset(), msg_ts(), [msg_input()]) -> iodata().
enc_records(_Offset, _TsBase, []) -> [];
enc_records(Offset, TsBase, [Msg | Batch]) ->
  [ enc_record(Offset, TsBase, Msg)
  | enc_records(Offset + 1, TsBase, Batch)
  ].

% NOTE Return {Meta, Batch :: [message()]} where Batch is a reversed
% RecordBatch =>
%   FirstOffset => int64
%   Length => int32
%   PartitionLeaderEpoch => int32 # client set whatever
%   Magic => int8 # The 17th byte as in v0 and v1
%   CRC => int32
%   Attributes => int16
%   LastOffsetDelta => int32
%   FirstTimestamp => int64
%   MaxTimestamp => int64
%   ProducerId => int64
%   ProducerEpoch => int16
%   FirstSequence => int32
%   Records => [Record]
-spec do_decode(offset(), binary()) -> {batch_meta(), [message()]}.
do_decode(Offset, <<_PartitionLeaderEpoch:32,
                    _Magic:8,
                    CRC:32/unsigned-integer,
                    T0/binary>>) ->
  CRC = crc32cer:nif(T0), %% assert
  {Attributes0,     T1} = dec(int16, T0),
  {LastOffsetDelta, T2} = dec(int32, T1),
  {FirstTimestamp,  T3} = dec(int64, T2),
  {MaxTimestamp,    T4} = dec(int64, T3),
  {ProducerId,      T5} = dec(int64, T4),
  {_ProducerEpoch,  T6} = dec(int16, T5),
  {_FirstSequence,  T7} = dec(int32, T6),
  {Count,           T8} = dec(int32, T7),
  Attributes = parse_attributes(Attributes0),
  Compression = maps:get(compression, Attributes),
  TsType = maps:get(ts_type, Attributes),
  RecordsBin = kpro_compress:decompress(Compression, T8),
  Messages = dec_records(Count, Offset, FirstTimestamp, TsType, RecordsBin),
  Meta = #{ is_transaction => maps:get(is_transaction, Attributes)
          , is_control => maps:get(is_control, Attributes)
          , last_offset => Offset + LastOffsetDelta
          , max_ts => MaxTimestamp
          , producer_id => ProducerId
          },
  {Meta, Messages}.

-spec dec_records(integer(), offset(), msg_ts(),
                  ts_type(), binary()) -> [message()].
dec_records(Count, Offset, Ts, TsType, Bin) ->
  dec_records(Count, Offset, Ts, TsType, Bin, []).

%% Messages are returned in reversed order
-spec dec_records(integer(), offset(), msg_ts(),
                  ts_type(), binary(), [message()]) -> [message()].
dec_records(0, _Offset, _Ts, _TsType, <<>>, Acc) ->
  %% NO reverse here
  Acc;
dec_records(Count, Offset, Ts, TsType, Bin, Acc) ->
  {Rec, Tail} = dec_record(Offset, Ts, TsType, Bin),
  dec_records(Count - 1, Offset, Ts, TsType, Tail, [Rec | Acc]).

% Record =>
%   Length => varint
%   Attributes => int8
%   TimestampDelta => varint
%   OffsetDelta => varint
%   KeyLen => varint
%   Key => data
%   ValueLen => varint
%   Value => data
%   Headers => [Header]
-spec dec_record(offset(), msg_ts(), ts_type(), binary()) ->
        {message(), binary()}.
dec_record(Offset, Ts, TsType, Bin) ->
  {_Len,        T0} = dec(varint, Bin),
  {_Attr,       T1} = dec(int8, T0),
  {TsDelta,     T2} = dec(varint, T1),
  {OffsetDelta, T3} = dec(varint, T2),
  {Key,         T4} = dec(bytes, T3),
  {Value,       T5} = dec(bytes, T4),
  {Headers,     T}  = dec_headers(T5),
  Msg = #kafka_message{ offset = Offset + OffsetDelta
                      , key = Key
                      , value = Value
                      , ts_type = TsType
                      , ts = Ts + TsDelta
                      , headers = Headers
                      },
  {Msg, T}.

% Record =>
%   Length => varint
%   Attributes => int8
%   TimestampDelta => varint
%   OffsetDelta => varint
%   KeyLen => varint
%   Key => data
%   ValueLen => varint
%   Value => data
%   Headers => [Header]
-spec enc_record(offset(), msg_ts(), msg_input()) -> iodata().
enc_record(Offset, TsBase, #{value := Value} = M) ->
  Ts = maps:get(ts, M, TsBase),
  Key = maps:get(key, M, <<>>),
  %% 'headers' is a non-nullable array
  %% do not encode 'undefined' -> -1
  Headers = maps:get(headers, M, []),
  Body = [ enc(int8, 0) % no per-message attributes in magic v2
         , enc(varint, Ts - TsBase)
         , enc(varint, Offset)
         , enc(bytes, Key)
         , enc(bytes, Value)
         , enc_headers(Headers)
         ],
  Size = kpro_lib:data_size(Body),
  [enc(varint, Size), Body].

enc_headers(Headers) ->
  Count = length(Headers),
  [ enc(varint, Count)
  | [enc_header(Header) || Header <- Headers]
  ].

% Header => HeaderKey HeaderVal
%   HeaderKeyLen => varint
%   HeaderKey => string
%   HeaderValueLen => varint
%   HeaderValue => data
enc_header({Key, Val}) ->
  [ enc(varint, size(Key))
  , Key
  , enc(varint, size(Val))
  , Val
  ].

-spec dec_headers(binary()) -> {headers(), binary()}.
dec_headers(Bin0) ->
  {Count, Bin} = dec(varint, Bin0),
  case Count =:= -1 of
    true -> {undefined, Bin};
    false -> dec_headers(Count, Bin, [])
  end.

% Header => HeaderKey HeaderVal
%   HeaderKeyLen => varint
%   HeaderKey => string
%   HeaderValueLen => varint
%   HeaderValue => data
dec_headers(0, Bin, Acc) ->
  {lists:reverse(Acc), Bin};
dec_headers(Count, Bin, Acc) ->
  {Key, T1} = dec(bytes, Bin),
  {Val, T}  = dec(bytes, T1),
  dec_headers(Count - 1, T, [{Key, Val} | Acc]).

dec(bytes, Bin) ->
  %% unlike old version bytes, length is varint in magic 2
  {Len, Rest} = dec(varint, Bin),
  kpro_lib:copy_bytes(Len, Rest);
dec(Primitive, Bin) ->
  kpro_lib:decode(Primitive, Bin).

enc(bytes, undefined) ->
  enc(varint, -1);
enc(bytes, <<>>) ->
  enc(varint, -1);
enc(bytes, Bin) ->
  Len = size(Bin),
  [enc(varint, Len), Bin];
enc(Primitive, Val) ->
  kpro_lib:encode(Primitive, Val).

% The lowest 3 bits contain the compression codec used for the message.
% The fourth lowest bit represents the timestamp type. 0 stands for CreateTime
%   and 1 stands for LogAppendTime. The producer should always set this bit to 0
%   (since 0.10.0)
% The fifth lowest bit indicates whether the RecordBatch is part of a
%   transaction or not. 0 indicates that the RecordBatch is not transactional,
%   while 1 indicates that it is. (since 0.11.0.0).
% The sixth lowest bit indicates whether the RecordBatch includes a control
%   message. 1 indicates that the RecordBatch contains a control message,
%   0 indicates that it doesn't. Control messages are used to enable txn.
%   in Kafka and are generated by the broker.
%   Clients should not return control batches (ie. those with this bit set)
%   to applications. (since 0.11.0.0)
parse_attributes(Attr) ->
  #{ compression => kpro_compress:codec_to_method(Attr)
   , ts_type => kpro_lib:get_ts_type(_MagicV = 2, Attr)
   , is_transaction => (Attr band (1 bsl 4)) =/= 0
   , is_control => (Attr band (1 bsl 5)) =/= 0
   }.

-spec encode_attributes(compress_option(), boolean()) -> iolist().
encode_attributes(Compression, IsTxn0) ->
  Codec = kpro_compress:method_to_codec(Compression),
  TsType = 0, % producer always set 0
  IsTxn = flag(IsTxn0, 1 bsl 4),
  IsCtrl = flag(false, 1 bsl 5),
  Result = Codec bor TsType bor IsTxn bor IsCtrl,
  %% yes, it's int16 for batch level attributes
  %% message level attributes (int8) are currently unused in magic v2
  %% and maybe get used in future magic versions
  enc(int16, Result).

flag(false, _) -> 0;
flag(true, BitMask) -> BitMask.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:

