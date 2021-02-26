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
          Encoded = kpro_batch:encode(V, [#{ts => kpro_lib:now_ts(),
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
  CompressionOpts = [no_compression, gzip, snappy, lz4],
  [{atom_to_list(CompressionOpt), " magic v" ++ integer_to_list(MagicV),
    fun() -> F(MagicV, CompressionOpt) end} ||
   CompressionOpt <- CompressionOpts,
   MagicV <- MagicVersions].

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
  Encoded = kpro_batch:encode(2, [#{ts => kpro_lib:now_ts(),
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

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
