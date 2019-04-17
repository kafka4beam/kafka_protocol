-module(kpro_v2).

-export([decodex/2]).

-record(kafka_message,
        { offset
        , magic_byte
        , attributes
        , key
        , value
        , crc
        , ts_type
        , ts
        }).

decodex(Offset, <<_PartitionLeaderEpoch:32,
                  _Magic:8,
                  _CRC:32/unsigned-integer,
                  T0/binary>>) ->
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
  RecordsBin = decompress(Compression, T8),
  Messages = dec_records(Count, Offset, FirstTimestamp, TsType, RecordsBin),
  Meta = #{ is_transaction => maps:get(is_transaction, Attributes)
          , is_control => maps:get(is_control, Attributes)
          , last_offset => Offset + LastOffsetDelta
          , max_ts => MaxTimestamp
          , producer_id => ProducerId
          },
  {Meta, Messages}.

dec_records(Count, Offset, Ts, TsType, Bin) ->
  dec_records(Count, Offset, Ts, TsType, Bin, []).

%% Messages are returned in reversed order
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
dec_record(Offset, Ts, TsType, Bin) ->
  {_Len,        T0} = dec(varint, Bin),
  {_Attr,       T1} = dec(int8, T0),
  {TsDelta,     T2} = dec(varint, T1),
  {OffsetDelta, T3} = dec(varint, T2),
  {Key,         T4} = dec(bytes, T3),
  {Value,       T5} = dec(bytes, T4),
  {_Headers,     T} = dec_headers(T5),
  Msg = #kafka_message{ offset = Offset + OffsetDelta
                      , key = Key
                      , value = Value
                      , ts_type = TsType
                      , ts = Ts + TsDelta
                      },
  {Msg, T}.

dec_headers(Bin0) ->
  {Count, Bin} = dec(varint, Bin0),
  case Count =:= -1 of
    true -> {undefined, Bin};
    false -> dec_headers(Count, Bin, [])
  end.

dec(bytes, Bin) ->
  %% unlike old version bytes, length is varint in magic 2
  {Len, Rest} = dec(varint, Bin),
  copy_bytes(Len, Rest);
dec(Primitive, Bin) ->
  decode(Primitive, Bin).

-define(INT, signed-integer).

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
decode(varint, Bin) ->
  decode_varint(Bin);
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

copy_bytes(-1, Bin) ->
  {<<>>, Bin};
copy_bytes(Size, Bin) ->
  <<Bytes:Size/binary, Rest/binary>> = Bin,
  {binary:copy(Bytes), Rest}.


dec_headers(0, Bin, Acc) ->
  {lists:reverse(Acc), Bin};
dec_headers(Count, Bin, Acc) ->
  {Key, T1} = dec(bytes, Bin),
  {Val, T}  = dec(bytes, T1),
  dec_headers(Count - 1, T, [{Key, Val} | Acc]).


parse_attributes(Attr) ->
  #{ compression => codec_to_method(Attr)
   , ts_type => get_ts_type(_MagicV = 2, Attr)
   , is_transaction => (Attr band (1 bsl 4)) =/= 0
   , is_control => (Attr band (1 bsl 5)) =/= 0
   }.

-define(KPRO_COMPRESS_NONE,   0).
-define(KPRO_COMPRESS_GZIP,   1).
-define(KPRO_COMPRESS_SNAPPY, 2).
-define(KPRO_COMPRESS_LZ4,    3).

-define(KPRO_COMPRESSION_MASK, 2#111).
-define(KPRO_IS_GZIP_ATTR(ATTR),
        ((?KPRO_COMPRESSION_MASK band ATTR) =:= ?KPRO_COMPRESS_GZIP)).
-define(KPRO_IS_SNAPPY_ATTR(ATTR),
        ((?KPRO_COMPRESSION_MASK band ATTR) =:= ?KPRO_COMPRESS_SNAPPY)).
-define(KPRO_IS_LZ4_ATTR(ATTR),
        ((?KPRO_COMPRESSION_MASK band ATTR) =:= ?KPRO_COMPRESS_LZ4)).

-define(KPRO_TS_TYPE_CREATE, 0).
-define(KPRO_TS_TYPE_APPEND, 2#1000).

-define(KPRO_TS_TYPE_MASK, 2#1000).
-define(KPRO_IS_CREATE_TS(ATTR), ((?KPRO_TS_TYPE_MASK band ATTR) =:= 0)).
-define(KPRO_IS_APPEND_TS(ATTR), ((?KPRO_TS_TYPE_MASK band ATTR) =/= 0)).


-define(no_compression, no_compression).
-define(gzip, gzip).
-define(snappy, snappy).
-define(lz4, lz4).

codec_to_method(A) when ?KPRO_IS_GZIP_ATTR(A) -> ?gzip;
codec_to_method(A) when ?KPRO_IS_SNAPPY_ATTR(A) -> ?snappy;
codec_to_method(A) when ?KPRO_IS_LZ4_ATTR(A) -> ?lz4;
codec_to_method(_) -> ?no_compression.

get_ts_type(0, _) -> undefined;
get_ts_type(_, A) when ?KPRO_IS_CREATE_TS(A) -> create;
get_ts_type(_, A) when ?KPRO_IS_APPEND_TS(A) -> append.

-define(MAX_BITS, 63).

decode_varint(Bin) ->
  dec_zigzag(dec_varint(Bin)).

dec_zigzag({Int, TailBin}) ->
  {(Int bsr 1) bxor -(Int band 1), TailBin}.

dec_varint(Bin) ->
  dec_varint(Bin, 0, 0).

dec_varint(Bin, Acc, AccBits) ->
  true = (AccBits =< ?MAX_BITS), %% assert
  <<Tag:1, Value:7, Tail/binary>> = Bin,
  NewAcc = (Value bsl AccBits) bor Acc,
  case Tag =:= 0 of
    true  -> {NewAcc, Tail};
    false -> dec_varint(Tail, NewAcc, AccBits + 7)
  end.

decompress(?no_compression, Bin) -> Bin;
decompress(M, B) -> kpro:decompress(M, B).
