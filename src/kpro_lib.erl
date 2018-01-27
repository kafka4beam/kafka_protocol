-module(kpro_lib).

-export([ copy_bytes/2
        , data_size/1
        , decode/2
        , encode/2
        , get_ts_type/2
        ]).

-include("kpro_private.hrl").

-define(IS_BYTE(I), (I>=0 andalso I<256)).

-type primitive_type() :: kpro:primitive_type().
-type primitive() :: kpro:primitive().
-type count() :: non_neg_integer().

%%%_* APIs =====================================================================

%% @doc Return number of bytes in the given `iodata()'.
-spec data_size(iodata()) -> count().
data_size(IoData) ->
  data_size(IoData, 0).

%% @doc Encode primitives.
-spec encode(primitive_type(), kpro:primitive()) -> iodata().
encode(boolean, true) -> <<1:8/?INT>>;
encode(boolean, false) -> <<0:8/?INT>>;
encode(int8,  I) when is_integer(I) -> <<I:8/?INT>>;
encode(int16, I) when is_integer(I) -> <<I:16/?INT>>;
encode(int32, I) when is_integer(I) -> <<I:32/?INT>>;
encode(int64, I) when is_integer(I) -> <<I:64/?INT>>;
encode(varint, I) when is_integer(I) -> kpro_varint:encode(I);
encode(nullable_string, ?null) -> <<-1:16/?INT>>;
encode(nullable_string, Str) -> encode(string, Str);
encode(string, Atom) when is_atom(Atom) ->
  encode(string, atom_to_binary(Atom, utf8));
encode(string, <<>>) -> <<0:16/?INT>>;
encode(string, L) when is_list(L) ->
  encode(string, iolist_to_binary(L));
encode(string, B) when is_binary(B) ->
  Length = size(B),
  <<Length:16/?INT, B/binary>>;
encode(bytes, ?null) -> <<-1:32/?INT>>;
encode(bytes, B) when is_binary(B) orelse is_list(B) ->
  Size = kpro_lib:data_size(B),
  case Size =:= 0 of
    true  -> <<-1:32/?INT>>;
    false -> [<<Size:32/?INT>>, B]
  end;
encode(records, B) ->
  encode(bytes, B).

%% @doc Decode primitives.
-spec decode(kpro:primitive_type(), binary()) -> {primitive(), binary()}.
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
  kpro_varint:decode(Bin);
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

%% @doc Make a copy of the head instead of keeping referencing the original.
-spec copy_bytes(-1 | count(), binary()) -> {undefined | binary(), binary()}.
copy_bytes(-1, Bin) ->
  {undefined, Bin};
copy_bytes(Size, Bin) ->
  <<Bytes:Size/binary, Rest/binary>> = Bin,
  {binary:copy(Bytes), Rest}.

-spec get_ts_type(byte(), byte()) -> kpro:ts_type().
get_ts_type(0, _) -> undefined;
get_ts_type(_, A) when ?KPRO_IS_CREATE_TS(A) -> create;
get_ts_type(_, A) when ?KPRO_IS_APPEND_TS(A) -> append.

%%%_* Internals ================================================================

-spec data_size(iodata(), count()) -> count().
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
