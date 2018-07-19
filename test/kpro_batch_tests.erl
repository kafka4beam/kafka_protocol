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
%%%
-module(kpro_batch_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro.hrl").

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
  [{"magic 0 no compression", fun() -> F(0, no_compression) end},
   {"magic 1 no compression", fun() -> F(1, no_compression) end},
   {"magic 2 no compression", fun() -> F(2, no_compression) end},
   {"magic 0 gzip", fun() -> F(0, gzip) end},
   {"magic 1 gzip", fun() -> F(1, gzip) end},
   {"magic 2 gzip", fun() -> F(2, gzip) end}
  ].

bin(X) ->
  iolist_to_binary(X).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
