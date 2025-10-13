%%%   Copyright (c) 2020-2021, Klarna Bank AB (publ)
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
-module(kpro_varint_tests).

-include_lib("eunit/include/eunit.hrl").

unsigned_test() ->
  ?assertEqual(<<0>>, bin(kpro_varint:encode_unsigned(0))),
  ?assertEqual(<<2#10101100, 2#00000010>>,
               bin(kpro_varint:encode_unsigned(300))).

%% Comprehensive varint encoding tests
encode_test_() ->
  [
    {"encode zero", fun() ->
      ?assertEqual(<<0>>, bin(kpro_varint:encode(0)))
    end},
    {"encode small positive", fun() ->
      ?assertEqual(<<254, 1>>, bin(kpro_varint:encode(127))),
      ?assertEqual(<<200, 1>>, bin(kpro_varint:encode(100)))
    end},
    {"encode small negative", fun() ->
      ?assertEqual(<<1>>, bin(kpro_varint:encode(-1))),
      ?assertEqual(<<3>>, bin(kpro_varint:encode(-2))),
      ?assertEqual(<<255, 1>>, bin(kpro_varint:encode(-128)))
    end},
    {"encode medium values", fun() ->
      ?assertEqual(<<128, 2>>, bin(kpro_varint:encode(128))),
      ?assertEqual(<<130, 2>>, bin(kpro_varint:encode(129))),
      ?assertEqual(<<254, 3>>, bin(kpro_varint:encode(255)))
    end},
    {"encode large values", fun() ->
      ?assertEqual(<<128, 128, 2>>, bin(kpro_varint:encode(16384))),
      ?assertEqual(<<254, 255, 255, 1>>, bin(kpro_varint:encode(2097151))),
      ?assertEqual(<<128, 128, 128, 2>>, bin(kpro_varint:encode(2097152)))
    end},
    {"encode edge cases", fun() ->
      ?assertEqual(<<254, 255, 255, 255, 1>>, bin(kpro_varint:encode(268435455)))
    end}
  ].

%% Comprehensive varint decoding tests
decode_test_() ->
  [
    {"decode zero", fun() ->
      ?assertEqual({0, <<>>}, kpro_varint:decode(<<0>>))
    end},
    {"decode small positive", fun() ->
      ?assertEqual({127, <<>>}, kpro_varint:decode(<<254, 1>>)),
      ?assertEqual({100, <<>>}, kpro_varint:decode(<<200, 1>>))
    end},
    {"decode small negative", fun() ->
      ?assertEqual({-1, <<>>}, kpro_varint:decode(<<1>>)),
      ?assertEqual({-2, <<>>}, kpro_varint:decode(<<3>>)),
      ?assertEqual({-128, <<>>}, kpro_varint:decode(<<255, 1>>))
    end},
    {"decode medium values", fun() ->
      ?assertEqual({128, <<>>}, kpro_varint:decode(<<128, 2>>)),
      ?assertEqual({129, <<>>}, kpro_varint:decode(<<130, 2>>)),
      ?assertEqual({255, <<>>}, kpro_varint:decode(<<254, 3>>))
    end},
    {"decode large values", fun() ->
      ?assertEqual({16384, <<>>}, kpro_varint:decode(<<128, 128, 2>>)),
      ?assertEqual({2097151, <<>>}, kpro_varint:decode(<<254, 255, 255, 1>>)),
      ?assertEqual({2097152, <<>>}, kpro_varint:decode(<<128, 128, 128, 2>>))
    end},
    {"decode with trailing data", fun() ->
      ?assertEqual({0, <<"hello">>}, kpro_varint:decode(<<0, "hello">>)),
      ?assertEqual({127, <<"world">>}, kpro_varint:decode(<<254, 1, "world">>))
    end}
  ].

%% Round-trip encoding/decoding tests
roundtrip_test_() ->
  TestValues = [
    0, 1, -1, 127, -127, 128, -128, 255, -255,
    1000, -1000, 16383, -16383, 16384, -16384,
    2097151, -2097151, 2097152, -2097152,
    268435455, -268435455
  ],
  [{"roundtrip " ++ integer_to_list(Val), fun() ->
    Encoded = kpro_varint:encode(Val),
    {Decoded, <<>>} = kpro_varint:decode(bin(Encoded)),
    ?assertEqual(Val, Decoded)
  end} || Val <- TestValues].

%% Unsigned varint tests
unsigned_comprehensive_test_() ->
  [
    {"unsigned encode zero", fun() ->
      ?assertEqual(<<0>>, bin(kpro_varint:encode_unsigned(0)))
    end},
    {"unsigned encode small", fun() ->
      ?assertEqual(<<1>>, bin(kpro_varint:encode_unsigned(1))),
      ?assertEqual(<<127>>, bin(kpro_varint:encode_unsigned(127))),
      ?assertEqual(<<128, 1>>, bin(kpro_varint:encode_unsigned(128)))
    end},
    {"unsigned encode large", fun() ->
      ?assertEqual(<<255, 255, 255, 255, 127>>, bin(kpro_varint:encode_unsigned(34359738367)))
    end},
    {"unsigned decode", fun() ->
      ?assertEqual({0, <<>>}, kpro_varint:decode_unsigned(<<0>>)),
      ?assertEqual({1, <<>>}, kpro_varint:decode_unsigned(<<1>>)),
      ?assertEqual({127, <<>>}, kpro_varint:decode_unsigned(<<127>>)),
      ?assertEqual({128, <<>>}, kpro_varint:decode_unsigned(<<128, 1>>)),
      ?assertEqual({300, <<>>}, kpro_varint:decode_unsigned(<<172, 2>>))
    end},
    {"unsigned roundtrip", fun() ->
      TestValues = [0, 1, 127, 128, 255, 1000, 16383, 16384, 2097151, 2097152, 268435455, 268435456, 34359738367],
      lists:foreach(fun(Val) ->
        Encoded = kpro_varint:encode_unsigned(Val),
        {Decoded, <<>>} = kpro_varint:decode_unsigned(bin(Encoded)),
        ?assertEqual(Val, Decoded)
      end, TestValues)
    end}
  ].

%% Zigzag encoding tests (internal functions, test through public API)
zigzag_roundtrip_test_() ->
  TestValues = [0, 1, -1, 127, -127, 128, -128, 1000, -1000, 16383, -16383, 16384, -16384],
  [{"zigzag roundtrip " ++ integer_to_list(Val), fun() ->
    Encoded = kpro_varint:encode(Val),
    {Decoded, <<>>} = kpro_varint:decode(bin(Encoded)),
    ?assertEqual(Val, Decoded)
  end} || Val <- TestValues].

%% Performance tests
performance_test_() ->
  [
    {"encode performance", fun() ->
      TestValues = lists:seq(1, 1000),
      StartTime = erlang:system_time(microsecond),
      lists:foreach(fun(Val) ->
        _ = kpro_varint:encode(Val)
      end, TestValues),
      EndTime = erlang:system_time(microsecond),
      EncodingTime = EndTime - StartTime,
      ?assert(EncodingTime < 10000) %% Should complete in <10ms
    end},
    {"decode performance", fun() ->
      TestValues = lists:seq(1, 1000),
      EncodedValues = [bin(kpro_varint:encode(Val)) || Val <- TestValues],
      StartTime = erlang:system_time(microsecond),
      lists:foreach(fun(Encoded) ->
        {_Decoded, _} = kpro_varint:decode(Encoded)
      end, EncodedValues),
      EndTime = erlang:system_time(microsecond),
      DecodingTime = EndTime - StartTime,
      ?assert(DecodingTime < 10000) %% Should complete in <10ms
    end}
  ].

%% Edge case tests
edge_cases_test_() ->
  [
    {"max supported signed integer", fun() ->
      MaxInt = 268435455,
      Encoded = kpro_varint:encode(MaxInt),
      {Decoded, <<>>} = kpro_varint:decode(bin(Encoded)),
      ?assertEqual(MaxInt, Decoded)
    end},
    {"min supported signed integer", fun() ->
      MinInt = -268435455,
      Encoded = kpro_varint:encode(MinInt),
      {Decoded, <<>>} = kpro_varint:decode(bin(Encoded)),
      ?assertEqual(MinInt, Decoded)
    end},
    {"max supported unsigned", fun() ->
      LargeUnsigned = 268435455,
      Encoded = kpro_varint:encode_unsigned(LargeUnsigned),
      {Decoded, <<>>} = kpro_varint:decode_unsigned(bin(Encoded)),
      ?assertEqual(LargeUnsigned, Decoded)
    end}
  ].

bin(IoData) -> iolist_to_binary(IoData).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
