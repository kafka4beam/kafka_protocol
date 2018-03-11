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
