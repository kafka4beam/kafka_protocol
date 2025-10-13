%%%   Copyright (c) 2018-2021, Klarna Bank AB (publ)
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

-module(kpro_varint).

-export([ encode/1
        , decode/1
        ]).

-export([ encode_unsigned/1
        , decode_unsigned/1
        ]).

-define(MAX_BITS, 63).

%% @doc Decode varint.
-compile({inline, [{decode, 1}]}).
-spec decode(binary()) -> {integer(), binary()}.
decode(Bin) ->
  dec_zigzag(dec_varint(Bin)).

%% @doc Encode varint.
-compile({inline, [{encode, 1}]}).
-spec encode(kpro:int64()) -> iodata().
encode(Int) ->
  enc_varint(enc_zigzag(Int)).

%% @doc Encode unsigned varint.
-compile({inline, [{encode_unsigned, 1}]}).
-spec encode_unsigned(non_neg_integer()) -> iodata().
encode_unsigned(Int) when Int >= 0 ->
  enc_varint(Int).

%% @doc Decode unsigned varint.
-compile({inline, [{decode_unsigned, 1}]}).
-spec decode_unsigned(binary()) -> {non_neg_integer(), binary()}.
decode_unsigned(Bin) ->
  dec_varint(Bin).

-compile({inline, [{enc_zigzag, 1}]}).
-spec enc_zigzag(integer()) -> non_neg_integer().
enc_zigzag(Int) ->
  true = (Int >= -(1 bsl ?MAX_BITS)),
  true = (Int < ((1 bsl ?MAX_BITS) - 1)),
  (Int bsl 1) bxor (Int bsr ?MAX_BITS).

-compile({inline, [{enc_varint, 1}]}).
-spec enc_varint(non_neg_integer()) -> binary().
enc_varint(I) when I =< 127 ->
  <<I:8>>;
enc_varint(I) when I =< 16383 ->  % 14 bits
  <<(128 bor (I band 127)):8, (I bsr 7):8>>;
enc_varint(I) when I =< 2097151 ->  % 21 bits
  <<(128 bor (I band 127)):8, (128 bor ((I bsr 7) band 127)):8, (I bsr 14):8>>;
enc_varint(I) when I =< 268435455 ->  % 28 bits
  <<(128 bor (I band 127)):8, (128 bor ((I bsr 7) band 127)):8,
    (128 bor ((I bsr 14) band 127)):8, (I bsr 21):8>>;
enc_varint(I) when I =< 34359738367 ->  % 35 bits
  <<(128 bor (I band 127)):8, (128 bor ((I bsr 7) band 127)):8,
    (128 bor ((I bsr 14) band 127)):8, (128 bor ((I bsr 21) band 127)):8,
    (I bsr 28):8>>.

-compile({inline, [{dec_zigzag, 1}]}).
-spec dec_zigzag({integer(), binary()} | integer()) ->
        {integer(), binary()} | integer().
dec_zigzag({Int, TailBin}) ->
  {(Int bsr 1) bxor -(Int band 1), TailBin}.

-spec dec_varint(binary()) -> {integer(), binary()}.
dec_varint(Bin) ->
  dec_varint(Bin, 0, 0).

-spec dec_varint(binary(), integer(), integer()) -> {integer(), binary()}.
dec_varint(Bin, Acc, AccBits) ->
  true = (AccBits =< ?MAX_BITS), %% assert
  <<Tag:1, Value:7, Tail/binary>> = Bin,
  NewAcc = (Value bsl AccBits) bor Acc,
  case Tag =:= 0 of
    true  -> {NewAcc, Tail};
    false -> dec_varint(Tail, NewAcc, AccBits + 7)
  end.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
