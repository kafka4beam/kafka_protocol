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

bin(IoData) -> iolist_to_binary(IoData).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
