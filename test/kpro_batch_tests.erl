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

encode_decode_test() ->
  Encoded = kpro_batch:encode([#{value => <<"v">>}], no_compression),
  [{_DummyMeta, [Decoded]}] = kpro_batch:decode(bin(Encoded)),
  ?assertMatch(#kafka_message{value = <<"v">>}, Decoded).

bin(X) ->
  iolist_to_binary(X).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
