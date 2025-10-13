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
%%%
-module(kpro_batch_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro.hrl").

-export([compress/1, decompress/1]).

encode_decode_test_() ->
  F = fun(V, Compression) ->
          Encoded = encode(V, [#{ts => kpro_lib:now_ts(),
                                 headers => [{<<"foo">>, <<"bar">>}],
                                 value => <<"v">>}], Compression),
          [{_DummyMeta, [Decoded]}] = kpro_batch:decode(bin(Encoded)),
          #kafka_message{ ts = Ts
                        , headers = Headers
                        , value = Value
                        } = Decoded,
          case V of
            0 -> ?assertEqual(undefined, Ts);
            _ -> ?assert(is_integer(Ts))
          end,
          case V of
            2 -> ?assertEqual([{<<"foo">>, <<"bar">>}], Headers);
            _ -> ?assertEqual([], Headers)
          end,
          ?assertMatch(<<"v">>, Value)
      end,
  MagicVersions = [0, 1, 2],
  CompressionOpts = [no_compression, gzip, snappy, lz4, zstd],
  [{atom_to_list(CompressionOpt), " magic v" ++ integer_to_list(MagicV),
    fun() -> F(MagicV, CompressionOpt) end} ||
   CompressionOpt <- CompressionOpts,
   MagicV <- MagicVersions].

encode_large_batch_test() ->
  %% Test encoding large batches (>1MB) with different compression options
  LargeBatch = make_large_batch(),

  %% Test with no compression
  {SizeNoComp, EncodedNoComp} = kpro_batch:encode(2, LargeBatch, no_compression),
  ?assert(SizeNoComp > 1024 * 1024), %% Should be >1MB
  ?assert(is_binary(bin(EncodedNoComp))),

  %% Test with gzip compression
  {SizeGzip, EncodedGzip} = kpro_batch:encode(2, LargeBatch, gzip),
  %% Compression may not always be smaller due to overhead, so just verify it's reasonable
  ?assert(SizeGzip > 0),
  ?assert(SizeGzip < SizeNoComp * 2), %% Should not be more than 2x larger
  ?assert(is_binary(bin(EncodedGzip))),

  %% Test with snappy compression
  {SizeSnappy, EncodedSnappy} = kpro_batch:encode(2, LargeBatch, snappy),
  %% Compression may not always be smaller due to overhead, so just verify it's reasonable
  ?assert(SizeSnappy > 0),
  ?assert(SizeSnappy < SizeNoComp * 2), %% Should not be more than 2x larger
  ?assert(is_binary(bin(EncodedSnappy))),

  %% Test with lz4 compression (if available)
  try
    {SizeLz4, EncodedLz4} = kpro_batch:encode(2, LargeBatch, lz4),
    ?assert(SizeLz4 > 0),
    ?assert(SizeLz4 < SizeNoComp * 2), %% Should not be more than 2x larger
    ?assert(is_binary(bin(EncodedLz4)))
  catch
    error:undef ->
      %% LZ4 not available, skip test
      ok
  end,

  %% Test with zstd compression (if available)
  try
    {SizeZstd, EncodedZstd} = kpro_batch:encode(2, LargeBatch, zstd),
    ?assert(SizeZstd > 0),
    ?assert(SizeZstd < SizeNoComp * 2), %% Should not be more than 2x larger
    ?assert(is_binary(bin(EncodedZstd)))
  catch
    error:undef ->
      %% ZSTD not available, skip test
      ok
  end,

  %% Verify we can decode the uncompressed batch
  [{_Meta, DecodedMessages}] = kpro_batch:decode(bin(EncodedNoComp)),
  ?assertEqual(length(LargeBatch), length(DecodedMessages)),

  %% Verify message content matches
  lists:foreach(fun({Original, Decoded}) ->
    #kafka_message{key = DecodedKey, value = DecodedValue, ts = DecodedTs} = Decoded,
    #{key := OriginalKey, value := OriginalValue, ts := OriginalTs} = Original,
    ?assertEqual(OriginalKey, DecodedKey),
    ?assertEqual(OriginalValue, DecodedValue),
    ?assertEqual(OriginalTs, DecodedTs)
  end, lists:zip(LargeBatch, DecodedMessages)),

  %% Test performance: encoding should complete in reasonable time
  StartTime = erlang:system_time(microsecond),
  _ = kpro_batch:encode(2, LargeBatch, no_compression),
  EndTime = erlang:system_time(microsecond),
  EncodingTime = EndTime - StartTime,
  ?assert(EncodingTime < 1000000), %% Should complete in <1 second

  ok.

make_large_batch() ->
  %% Create a batch that will be >1MB total
  %% Each message is ~100KB, so 11 messages = ~1.1MB total
  MessageCount = 11,
  MessageSize = 100 * 1024, %% 100KB per message

  [#{ ts => kpro_lib:now_ts() + N * 1000 %% Different timestamps
    , key => <<"large_msg_key_", (integer_to_binary(N))/binary>>
    , value => crypto:strong_rand_bytes(MessageSize)
    , headers => [{<<"header_key_", (integer_to_binary(N))/binary>>,
                   <<"header_value_", (integer_to_binary(N))/binary>>}]
    } || N <- lists:seq(1, MessageCount)].

provide_compression_test() ->
  kpro:provide_compression([{snappy, ?MODULE}]),
  try
    test_provide_compression(snappy)
  after
    persistent_term:erase({kpro_compress, snappy})
  end.

provide_compression_from_app_env_test() ->
  ?assertEqual("notset", persistent_term:get({kpro_compress, lz4}, "notset")),
  application:load(?APPLICATION),
  application:set_env(?APPLICATION, provide_compression, [{lz4, ?MODULE}]),
  application:ensure_all_started(?APPLICATION),
  ?assertEqual(?MODULE, persistent_term:get({kpro_compress, lz4})),
  try
    test_provide_compression(lz4)
  after
    persistent_term:erase({kpro_compress, lz4})
  end.

test_provide_compression(Name) ->
  Encoded = encode(2, [#{ts => kpro_lib:now_ts(),
                         headers => [{<<"foo">>, <<"bar">>}],
                         value => <<"v">>}], Name),
  ?assertMatch({_, _}, binary:match(bin(Encoded), <<"fake-compressed">>)),
  [{_DummyMeta, [Decoded]}] = kpro_batch:decode(bin(Encoded)),
  #kafka_message{value = Value} = Decoded,
  ?assertMatch(<<"v">>, Value).

%% fake compression for test
compress(IoData) -> {ok, ["fake-compressed", IoData]}.

decompress(<<"fake-compressed", Data/binary>>) -> Data.

bin(X) ->
  iolist_to_binary(X).

encode(MagicVsn, Batch, Compression) ->
  {_Size, IoList} = kpro_batch:encode(MagicVsn, Batch, Compression),
  IoList.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
