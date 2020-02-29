%%%   Copyright (c) 2020, Klarna AB
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

-module(kpro_produce_req_encode_benchmark_tests).
-include_lib("eunit/include/eunit.hrl").
-include("kpro.hrl").

-define(ITERATIONS, 49999).

run_test_() ->
  Batch = make_batch(1),
  %{Min, Max} = kpro_schema:vsn_range(produce),
  [{"encode benchmark test for version " ++ integer_to_list(V),
    {timeout, timer:seconds(30),
     fun() ->
      run_test(Batch, V)
     end}} || V <- lists:seq(2, 3)].

run_test(Batch, Vsn) ->
  lists:foreach(fun(_) ->
                    make_req(Vsn, Batch)
                end, lists:seq(0, ?ITERATIONS)).

make_req(Vsn, Batch) ->
  kpro_req_lib:produce(Vsn, <<"dummy-topic-name">>, 0, Batch).

make_batch(BatchSize) ->
  F = fun(I) ->
          #{key => iolist_to_binary("key" ++ integer_to_list(I)),
            value => make_value()
           }
      end,
  [F(I) || I <- lists:seq(1, BatchSize)].

make_value() ->
  crypto:strong_rand_bytes(1024).

