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

-module(kpro_varint).

-export([ encode/1
        , decode/1
        ]).

-define(MAX_BITS, 63).

%% @doc Decode varint.
-spec decode(binary()) -> {integer(), binary()}.
decode(Bin) ->
  dec_zigzag(dec_varint(Bin)).

%% @doc Encode varint.
-spec encode(kpro:int64()) -> binary().
encode(Int) ->
  Bytes = enc_varint(enc_zigzag(Int)),
  iolist_to_binary(Bytes).

-spec enc_zigzag(integer()) -> non_neg_integer().
enc_zigzag(Int) ->
  true = (Int >= -(1 bsl ?MAX_BITS)),
  true = (Int < ((1 bsl ?MAX_BITS) - 1)),
  (Int bsl 1) bxor (Int bsr ?MAX_BITS).

-spec enc_varint(non_neg_integer()) -> iodata().
enc_varint(I) ->
  H = I bsr 7,
  L = I band 127,
  case H =:= 0 of
    true  -> [L];
    false -> [128 + L | enc_varint(H)]
  end.

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
