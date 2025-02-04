%%%   Copyright (c) 2018-2021, Klarna Bank AB (publ)
%%%   Copyright (c) 2022-2025, Kafka4beam contributors.
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

-module(kpro_compress).

-export([ compress/2
        , decompress/2
        , codec_to_method/1
        , method_to_codec/1
        , provide/1
        ]).

-include("kpro_private.hrl").

%% @doc Set snappy, lz4 or zstd compression modules.
%% This should override the default usage of `snappyer', `lz4b_frame' and `ezstd'.
-spec provide([{snappy | lz4 | zstd, module()}]) -> ok.
provide(Libs) ->
  lists:foreach(fun({Name, Module}) ->
                    persistent_term:put({?MODULE, Name}, Module)
                end, Libs).

%% @doc Translate codec in kafka batch attributes to compression method.
-spec codec_to_method(byte()) -> kpro:compress_option().
codec_to_method(A) when ?KPRO_IS_GZIP_ATTR(A) -> ?gzip;
codec_to_method(A) when ?KPRO_IS_SNAPPY_ATTR(A) -> ?snappy;
codec_to_method(A) when ?KPRO_IS_LZ4_ATTR(A) -> ?lz4;
codec_to_method(A) when ?KPRO_IS_ZSTD_ATTR(A) -> ?zstd;
codec_to_method(_) -> ?no_compression.

%% @doc Translate compression method to bits for kafka batch attributes.
method_to_codec(?gzip) -> ?KPRO_COMPRESS_GZIP;
method_to_codec(?snappy) -> ?KPRO_COMPRESS_SNAPPY;
method_to_codec(?lz4) -> ?KPRO_COMPRESS_LZ4;
method_to_codec(?zstd) -> ?KPRO_COMPRESS_ZSTD;
method_to_codec(?no_compression) -> ?KPRO_COMPRESS_NONE.

%% @doc Compress encoded batch.
-spec compress(kpro:compress_option(), iodata()) -> iodata().
compress(?no_compression, IoData) -> IoData;
compress(?gzip, IoData) -> zlib:gzip(IoData);
compress(Name, IoData) -> do_compress(Name, IoData).

%% @doc Decompress batch.
-spec decompress(kpro:compress_option(), binary()) -> binary().
decompress(?no_compression, Bin) -> Bin;
decompress(?gzip, Bin)           -> zlib:gunzip(Bin);
decompress(?snappy, Bin)         -> java_snappy_unpack(Bin);
decompress(?lz4, Bin)            -> do_decompress(?lz4, Bin);
decompress(?zstd, Bin)           -> do_decompress(?zstd, Bin).

%%%_* Internals ================================================================

%% Java snappy implementation has its own non-standard
%% magic header, see org/xerial/snappy/SnappyCodec.java
java_snappy_unpack(<<130, "SNAPPY", 0,
                     _Version:32, _MinCompatibleV:32, Chunks/binary>>) ->
  java_snappy_unpack_chunks(Chunks, []);
java_snappy_unpack(Bin) ->
  do_decompress(snappy, Bin).

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
      Decompressed = do_decompress(?snappy, Data),
      java_snappy_unpack_chunks(Tail, [Acc, Decompressed])
  end.

do_compress(Name, IoData) ->
    Module = get_module(Name),
    Data = maybe_convert_iodata_to_binary(Module, IoData),
    iodata(Module:compress(Data)).

do_decompress(Name, Bin) ->
    Module = get_module(Name),
    iodata(Module:decompress(Bin)).

get_module(?snappy) ->
    get_module(?snappy, snappyer);
get_module(?lz4) ->
    get_module(?lz4, lz4b_frame);
get_module(?zstd) ->
    get_module(?zstd, ezstd).

get_module(Name, Default) ->
    persistent_term:get({?MODULE, Name}, Default).

maybe_convert_iodata_to_binary(ezstd, IoData) -> iolist_to_binary(IoData);
maybe_convert_iodata_to_binary(_Module, IoData) -> IoData.

iodata({ok, IoData}) -> IoData;
iodata({error, Reason}) -> error(Reason);
iodata(IoData) when is_list(IoData) orelse is_binary(IoData) -> IoData.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
