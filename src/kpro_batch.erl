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

% Structures of kafka magic version 2.
% For v0 and v1, see `kpro_batch_v01'.
% In `kafka_protocol', there is no message version number in APIs,
% the input pattern is used to figure out version number:
% `[{Key, Value}]' : 0
% `[{Timestamp, Key, Value}]': 1
% `[#{headers => Headers, ts => Ts, key => Key, value => Value}]': 2

-module(kpro_batch).

-export([ decode/1
        , encode/2
        , encode_tx/2
        , encode_with_dummy_meta/2
        ]).

-include("kpro_private.hrl").

-type message() :: kpro:message().
-type ts_type() :: kpro:timestamp_type().
-type msg_ts() :: kpro:msg_ts().
-type msg_input() :: kpro:msg_input().
-type compress_option() :: kpro:compress_option().
-type batch_input() :: kpro:batch_input().
-type meta_input() :: kpro:meta_input().
-type batch_meta() :: kpro:batch_meta().
-type batch_attributes() :: kpro:batch_attributes().
-type offset() :: kpro:offset().
-type headers() :: kpro:headers().
-define(NO_META, ?KPRO_NO_BATCH_META).

%% @doc Encode a list of batch inputs into byte stream.
%% Depending on the input pattern, if it is magic version 0 - 1
%% call kpro_batch_v01 to do the work.
%% If it is magic version 2, encode with dummy (non-transactional) batch meta.
-spec encode(batch_input(), compress_option()) -> binary().
encode([#{} | _] = Batch, Compression) ->
  encode_with_dummy_meta(Batch, Compression);
encode(Batch, Compression) ->
  iolist_to_binary(kpro_batch_v01:encode(Batch, Compression)).

%% @doc Encode a list of batch inputs with dummy (non-transactional info) meta.
-spec encode_with_dummy_meta(batch_input(), compress_option()) -> binary().
encode_with_dummy_meta(Batch, Compression) ->
  Meta = dummy_meta(Compression),
  iolist_to_binary(encode_tx(Meta, Batch)).

%% @doc Encode a batch of magic version 2.
%% @end
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
-spec encode_tx(meta_input(), batch_input()) -> iodata().
encode_tx(#{ attributes := Attributes
           , producer_id := ProducerId
           , producer_epoch := ProducerEpoch
           , first_sequence := FirstSequence
           }, [FirstMsg | _] = Batch) ->
  FirstTimestamp =
    case maps:get(ts, FirstMsg, false) of
      false -> kpro_lib:now_ts();
      Ts -> Ts
    end,
  EncodedBatch = encode_batch(Attributes, FirstTimestamp, Batch),
  EncodedAttributes = encode_attributes(Attributes),
  PartitionLeaderEpoch = -1, %% producer can set whatever
  FirstOffset = 0, %% always 0
  Magic = 2, %% always 2
  {Count, MaxTimestamp} = scan_max_ts(1, FirstTimestamp, tl(Batch)),
  LastOffsetDelta = Count - 1, %% always count - 1 for producer
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

%%%_* Internals ================================================================

-spec decode(binary(), Acc) -> Acc when Acc :: [{batch_meta(), [message()]}].
decode(<<Offset:64, L:32, Body:L/binary, Rest/binary>>, Acc) ->
  <<_:32, Magic:8, _:32, _/binary>> = Body,
  Batch = case Magic < 2 of
            true  -> {?NO_META, kpro_batch_v01:decode(Offset, Body)};
            false -> do_decode(Offset, Body)
          end,
  NewAcc = add_batch(Batch, Acc),
  decode(Rest, NewAcc);
decode(_IncompleteTail, Acc) ->
  lists:reverse(reverse_hd_messages(Acc)).

%% Prepend newly decoded batch to the batch collection.
%% Since legacy batches (magic v0-1) have no batch meta info,
%% merge it to the list-head batch if it is also a legacy batch
-spec add_batch(Batch, [Batch]) -> [Batch]
        when Batch :: {batch_meta(), [message()]}.
add_batch({?NO_META, New}, [{?NO_META, Old} | R]) ->
  [{?NO_META, New ++ Old} | R];
add_batch(Batch, Acc) ->
  [Batch | reverse_hd_messages(Acc)].

-spec reverse_hd_messages([Batch]) -> [Batch]
        when Batch :: {batch_meta(), [message()]}.
reverse_hd_messages([]) -> [];
reverse_hd_messages([{Meta, Messages} | R]) ->
  [{Meta, lists:reverse(Messages)} | R].

-spec scan_max_ts(pos_integer(), msg_ts(), batch_input()) ->
        {pos_integer(), msg_ts()}.
scan_max_ts(Count, MaxTs, []) -> {Count, MaxTs};
scan_max_ts(Count, MaxTs0, [#{ts := Ts} | Rest]) ->
  MaxTs = max(MaxTs0, Ts),
  scan_max_ts(Count + 1, MaxTs, Rest);
scan_max_ts(Count, MaxTs, [#{} | Rest]) ->
  scan_max_ts(Count + 1, MaxTs, Rest).

-spec encode_batch(batch_attributes(), msg_ts(), [msg_input()]) -> iodata().
encode_batch(Attributes, TsBase, Batch) ->
  Compression = proplists:get_value(compression, Attributes, ?no_compression),
  Encoded0 = enc_records(_Offset = 0, TsBase, Batch),
  Encoded = kpro_compress:compress(Compression, Encoded0),
  Encoded.

-spec enc_records(offset(), msg_ts(), [msg_input()]) -> iodata().
enc_records(_Offset, _TsBase, []) -> [];
enc_records(Offset, TsBase, [Msg | Batch]) ->
  [ enc_record(Offset, TsBase, Msg)
  | enc_records(Offset + 1, TsBase, Batch)
  ].

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
  {ProducerEpoch,   T6} = dec(int16, T5),
  {FirstSequence,   T7} = dec(int32, T6),
  {Count,           T8} = dec(int32, T7),
  Attributes = parse_attributes(Attributes0),
  TsType = proplists:get_value(ts_type, Attributes),
  Compression = proplists:get_value(compression, Attributes),
  RecordsBin = kpro_compress:decompress(Compression, T8),
  Messages = dec_records(Count, Offset, FirstTimestamp, TsType, RecordsBin),
  Meta = #{ first_offset => Offset
          , magic => 2
          , crc => CRC
          , attributes => Attributes
          , last_offset_delta => LastOffsetDelta
          , first_ts => FirstTimestamp
          , max_ts => MaxTimestamp
          , producer_id => ProducerId
          , producer_epoch => ProducerEpoch
          , first_sequence => FirstSequence
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
  {Attr,        T1} = dec(int8, T0),
  {TsDelta,     T2} = dec(varint, T1),
  {OffsetDelta, T3} = dec(varint, T2),
  {Key,         T4} = dec(bytes, T3),
  {Value,       T5} = dec(bytes, T4),
  {Headers,     T}  = dec_headers(T5),
  Msg = #kafka_message{ offset = Offset + OffsetDelta
                      , magic_byte = 2
                      , attributes = Attr
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
  Body = [ enc(int8, 0) %% no per-message attributes in magic 2
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
  %% TODO: check int32 or varint
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
  %% TODO: check int32 or varint
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
%   message. 1 indicates that the RecordBatch is contains a control message,
%   0 indicates that it doesn't. Control messages are used to enable transactions
%   in Kafka and are generated by the broker.
%   Clients should not return control batches (ie. those with this bit set)
%   to applications. (since 0.11.0.0)
-spec parse_attributes(byte()) -> batch_attributes().
parse_attributes(Attr) ->
  [ {compression, kpro_compress:codec_to_method(Attr)}
  , {ts_type, kpro_lib:get_ts_type(_MagicV = 2, Attr)}
  , {is_transaction, (Attr band (1 bsl 4)) =/= 0}
  , {is_control, (Attr band (1 bsl 5)) =/= 0}
  ].

-spec encode_attributes(batch_attributes()) -> binary().
encode_attributes(Attr) ->
  Compression = proplists:get_value(compression, Attr, ?no_compression),
  Codec = kpro_compress:method_to_codec(Compression),
  TsType = 0, %% producer always set 0
  IsTxn = flag(proplists:get_bool(is_transaction, Attr), 1 bsl 4),
  IsCtrl = flag(proplists:get_bool(is_control, Attr), 1 bsl 5),
  Result = Codec bor TsType bor IsTxn bor IsCtrl,
  %% yes, it's int16 for batch level attributes
  enc(int16, Result).

flag(false, _) -> 0;
flag(true, BitMask) -> BitMask.

%% Make a dummy meta-input.
-spec dummy_meta(compress_option()) -> meta_input().
dummy_meta(Compression) ->
  Attributes = [{compression, Compression}],
  ProducerId = -1, %% non-transactional
  ProducerEpoch = -1, %% non-transactional
  FirstSequence = -1, %% non-transactional
  #{ attributes => Attributes
   , producer_id => ProducerId
   , producer_epoch => ProducerEpoch
   , first_sequence => FirstSequence
   }.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:

