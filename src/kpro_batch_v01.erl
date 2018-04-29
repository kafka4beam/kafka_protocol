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

% Structures of kafka message v0 and v1
%
% v0
% Message => Offset Size Crc MagicByte Attributes Key Value
%   Offset => int64
%   Size => int32
%   Crc => int32
%   MagicByte => int8
%   Attributes => int8
%   Key => bytes
%   Value => bytes
%
% v1 (supported since 0.10.0)
% Message => Offset Size Crc MagicByte Attributes Key Value
%   Offset => int64
%   Size => int32
%   Crc => int32
%   MagicByte => int8
%   Attributes => int8
%   Timestamp => int64
%   Key => bytes
%   Value => bytes

-module(kpro_batch_v01).

-export([ decode/2
        , encode/2
        ]).

-type msg_in() :: kpro:kv() | kpro:tkv().
-type msg_ts() :: kpro:msg_ts().
-type key() :: kpro:key().
-type value() :: kpro:value().
-type kv_list() :: kpro:kv_list().
-type compress_option() :: kpro:compress_option().
-type offset() :: kpro:offset().
-type message() :: kpro:message().

-include("kpro_private.hrl").

-define(NO_TIMESTAMP, -1).

%%%_* APIs =====================================================================

-spec encode(kv_list(), compress_option()) -> iodata().
encode(KvList, Compression) ->
  {Encoded, WrapperTs} = do_encode_messages(KvList),
  case Compression =:= ?no_compression of
    true -> Encoded;
    false -> compress(Compression, Encoded, WrapperTs)
  end.

%% @doc Decode one message or a compressed batch.
%% NOTE: Messages are returned in reversed order, so it's cheaper for caller
%% to concatenate (++) a short header to a long tail.
%% @end
%% Comment is copied from:
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
-spec decode(offset(), binary()) -> [message()].
decode(Offset, <<CRC:32/unsigned-integer, Body/binary>>) ->
  CRC = erlang:crc32(Body), %% assert
  {MagicByte, Rest0} = dec(int8, Body),
  {Attributes, Rest1} = dec(int8, Rest0),
  Compression = kpro_compress:codec_to_method(Attributes),
  TsType = kpro_lib:get_ts_type(MagicByte, Attributes),
  {Ts, Rest2} =
    case TsType of
      undefined -> {undefined, Rest1};
      _         -> dec(int64, Rest1)
    end,
  {Key, Rest} = dec(bytes, Rest2),
  {Value, <<>>} = dec(bytes, Rest),
  case Compression =:= ?no_compression of
    true ->
      Msg = #kafka_message{ offset = Offset
                          , value = Value
                          , key = Key
                          , ts = Ts
                          , ts_type = TsType
                          },
      [Msg];
    false ->
      Bin = kpro_compress:decompress(Compression, Value),
      MsgsReversed = decode_loop(Bin, []),
      maybe_assign_offsets(Offset, MsgsReversed)
  end.

%%%_* Internals ================================================================

%% Decode byte stream of kafka messages.
%% Messages are returned in reversed order
-spec decode_loop(binary(), [message()]) -> [message()].
decode_loop(<<>>, Acc) ->
  %% Assert <<>> tail because a recursive (compressed) batch
  %% should never be partitially delivered
  Acc;
decode_loop(<<O:64/?INT, L:32/?INT, Body:L/binary, Rest/binary>>, Acc) ->
  Messages = decode(O, Body),
  decode_loop(Rest, Messages ++ Acc).

-spec nested(msg_in()) -> kv_list() | false.
nested({_K, [Msg | _] = Nested}) when is_tuple(Msg) -> Nested;
nested({_T, _K, [Msg | _] = Nested}) when is_tuple(Msg) -> Nested;
nested(_) -> false.

-spec foldl_kvlist(fun((msg_in(), term()) -> term()),
                   term(), kv_list()) -> term().
foldl_kvlist(_Fun, Acc, []) -> Acc;
foldl_kvlist(Fun, Acc, [Msg | Rest]) ->
  NewAcc = case nested(Msg) of
             false -> Fun(Msg, Acc);
             Nested -> foldl_kvlist(Fun, Acc, Nested)
           end,
  foldl_kvlist(Fun, NewAcc, Rest).

%% Assign relative offsets to help kafka save some CPU when compressed.
%% Kafka will decompress to validate CRC, and assign real or relative offsets
%% depending on kafka verson and/or broker config. For 0.10 or later if relative
%% offsets are correctly assigned by producer, kafka will take the original
%% compressed batch as-is instead of reassign offsets then re-compress.
%% ref: https://cwiki.apache.org/confluence/display/KAFKA/ \
%%           KIP-31+-+Move+to+relative+offsets+in+compressed+message+sets
%%
%% Also try to find out the timestamp for compressed wrapper message.
%% In case all messages have timestamp, i.e. of spec `{T, K, V}', the max
%% timestamp is to be used for the wrapper.
%% In case all messages have no timestamp, i.e. of spec `{K, V}', default
%% value -1 (as in 'no timestamp') is used for wrapper.
%% In case of mixed presence, `false' is returned to indicate that the batch
%% should not be compressed otherwise kafka will consider it 'corrupted'.
-spec do_encode_messages(kv_list()) -> {iodata(), msg_ts() | false}.
do_encode_messages(KvList) ->
  F = fun(Msg, {Acc, Offset, MaxTs, KvCount0}) ->
          {T, K, V, KvCount} =
            case Msg of
              {Kx, Vx}     -> {?NO_TIMESTAMP, Kx, Vx, KvCount0 + 1};
              {Tx, Kx, Vx} -> {Tx, Kx, Vx, KvCount0}
            end,
          Encoded = encode_message(?KPRO_COMPRESS_NONE, T, K, V, Offset),
          {[Encoded | Acc], Offset + 1, erlang:max(MaxTs, T), KvCount}
      end,
  {Stream, _Offset, MaxTs, KvCount} =
    foldl_kvlist(F, {[], _Offset0 = 0, ?NO_TIMESTAMP, _KvCount = 0}, KvList),
  WrapperTs = case KvCount > 0 andalso MaxTs =/= ?NO_TIMESTAMP of
                true  -> false; %% some are {K, V} some are {T, K, V}
                false -> MaxTs
              end,
  {lists:reverse(Stream), WrapperTs}.

%% Encode one message, magic version 0 or 1 is taken from with or without
%% timestamp given at the 2nd arg.
-spec encode_message(byte(), msg_ts(), key(), value(), offset()) -> iodata().
encode_message(Codec, T, Key, Value, Offset) ->
  {MagicByte, CreateTs, Attributes} =
    case T of
      ?NO_TIMESTAMP ->
        {?KPRO_MAGIC_0, <<>>, Codec};
      _ ->
        {?KPRO_MAGIC_1, enc(int64, T), Codec bor ?KPRO_TS_TYPE_CREATE}
    end,
  Body = [ enc(int8, MagicByte)
         , enc(int8, Attributes)
         , CreateTs
         , enc(bytes, Key)
         , enc(bytes, Value)
         ],
  Crc  = enc(int32, erlang:crc32(Body)),
  Size = kpro_lib:data_size([Crc, Body]),
  [enc(int64, Offset),
   enc(int32, Size),
   Crc, Body
  ].

-spec compress(compress_option(), iodata(), msg_ts() | false) -> iodata().
compress(_Method, IoData, false) -> IoData; %% no way to compress
compress(Method, IoData, WrapperMsgTs) ->
  Key = <<>>,
  Value = kpro_compress:compress(Method, IoData),
  Codec = kpro_compress:method_to_codec(Method),
  %% Wrapper message offset for 0.10 or prior is ignored.
  %% For 0.11 or later, broker accepts only one of below:
  %%  - 0: special treat for C++ client, we use it here for simplicity
  %%  - Relative offset of the last message in the inner batch
  %%  - The absolute offset in kafka which is unknown to clients
  WrapperOffset = 0,
  encode_message(Codec, WrapperMsgTs, Key, Value, WrapperOffset).

%% Kafka may assign relative or real offsets for compressed messages.
-spec maybe_assign_offsets(offset(), [message()]) -> [message()].
maybe_assign_offsets(Offset, [#kafka_message{offset = Offset} | _] = Msgs) ->
  %% broker assigned 'real' offsets to the messages
  %% either downverted for version 0~2 fetch request
  %% or message format is 0.9.0.0 on disk
  %% do nothing
  Msgs;
maybe_assign_offsets(MaxOffset,
                     [#kafka_message{offset = MaxRelative} | _] = Msgs) ->
  BaseOffset = MaxOffset - MaxRelative,
  true = (BaseOffset >= 0), %% assert
  lists:map(fun(#kafka_message{offset = RelativeOffset} = M) ->
                M#kafka_message{offset = BaseOffset + RelativeOffset}
            end, Msgs).

dec(Primitive, Bin) -> kpro_lib:decode(Primitive, Bin).

enc(Primitive, Val) -> kpro_lib:encode(Primitive, Val).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
