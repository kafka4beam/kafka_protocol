-module(kpro_compatibility_tests).
-include_lib("eunit/include/eunit.hrl").
-include("kpro.hrl").

api_versions_v0_tail_test_() ->
  [?_assertMatch(#kpro_rsp{msg = #{error_code := no_error, api_keys := []}},
      kpro_rsp_lib:decode(api_versions, 0, <<0:16, 0:32, Tail/binary>>, false))
   || Tail <- [<<>>, <<0:32>>, <<1, 2, 3>>, <<255:64>>]].

strict_responses_test_() ->
  [?_assertException(error, _, kpro_rsp_lib:decode(API, Vsn, Body, false))
   || {API, Vsn, Body} <- [{api_versions, 0, <<0:16, 1:32, 17:16, 0:16>>},
                           {api_versions, 0, <<0:16, -2:32/signed>>},
                           {api_versions, 1, <<0:16, 0:32, 0:32, 1>>},
                           {sasl_handshake, 1, <<0:16, 0:32, 1>>}]].
