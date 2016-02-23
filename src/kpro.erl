
-module(kpro).

-export([ decode_response/1
        , encode_request/1
        ]).

%% exported for internal use
-export([ decode/2
        , decode_fields/3
        , encode/1
        ]).

-include("kpro.hrl").

-define(INT, signed-integer).

%% @doc Encode #kpro_Request{} records into kafka wire format.
-spec encode_request(kpro_Request()) -> iodata().
encode_request(#kpro_Request{ apiKey         = ApiKey
                            , apiVersion     = ApiVersion
                            , correlationId  = CorrId0
                            , clientId       = ClientId
                            , requestMessage = RequestMessage
                            }) ->
  true = (CorrId0 =< ?MAX_CORR_ID), %% assert
  CorrId = (ApiKey bsl ?CORR_ID_BITS) band CorrId0,
  IoData =
    [ encode({int16, ApiKey})
    , encode({int16, ApiVersion})
    , encode({int32, CorrId})
    , encode({string, ClientId})
    , encode(RequestMessage)
    ],
  Size = data_size(IoData),
  [encode({int32, Size}), IoData].

%% @doc Decode responses received from kafka.
%% {incomplete, TheOriginalBinary} is returned if this is not a complete packet.
%% @end
-spec decode_response(binary()) -> {incomplete | #kpro_Response{}, binary()}.
decode_response(Bin) ->
  {Size, Rest} = decode(int32, Bin),
  case size(Rest) >= Size of
    true  -> do_decode_response(Rest);
    false -> {incomplete, Bin}
  end.

decode_fields(RecordName, FieldTypes, Bin) ->
  {FieldValues, BinRest} = do_decode_fields(FieldTypes, Bin, _Acc = []),
  %% make the record.
  {list_to_tuple([RecordName | FieldValues]), BinRest}.

%%%_* Internal functions =======================================================

encode({int8,  I}) -> <<I:8/?INT>>;
encode({int16, I}) -> <<I:16/?INT>>;
encode({int32, I}) -> <<I:32/?INT>>;
encode({int64, I}) -> <<I:64/?INT>>;
encode({string, undefined}) ->
  <<-1:16/?INT>>;
encode({string, L}) when is_list(L) ->
  encode({string, iolist_to_binary(L)});
encode({string, B}) when is_binary(B) ->
  Length = size(B),
  <<Length:16/?INT, B/binary>>;
encode({bytes, undefined}) ->
  <<-1:32/?INT>>;
encode({bytes, B}) when is_binary(B) ->
  Length = size(B),
  <<Length:32/?INT, B/binary>>;
encode({{array, T}, L}) when is_list(L) ->
  true = ?is_kafka_primitive(T), %% assert
  Length = length(L),
  [<<Length:32/?INT>>, [encode({T, I}) || I <- L]];
encode({array, L}) when is_list(L) ->
  Length = length(L),
  [<<Length:32/?INT>>, [encode(I) || I <- L]];
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
decode(StructName, Bin) when is_atom(StructName) ->
  kpro_structs:decode(StructName, Bin).

do_decode_fields([], Bin, Acc) ->
  {lists:reverse(Acc), Bin};
do_decode_fields([FieldType | Rest], Bin, Acc) ->
  {FieldValue, BinRest} = decode(FieldType, Bin),
  do_decode_fields(Rest, BinRest, [FieldValue | Acc]).

do_decode_response(Bin) ->
  <<I:32/integer, Rest0/binary>> = Bin,
  ApiKey = I bsr ?CORR_ID_BITS,
  CorrId = I band ?MAX_CORR_ID,
  Type = ?API_KEY_TO_RSP(ApiKey),
  {Message, Rest} = decode(Type, Rest0),
  Result =
    #kpro_Response{ correlationId   = CorrId
                  , responseMessage = Message
                  },
  {Result, Rest}.

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

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
