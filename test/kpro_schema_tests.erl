-module(kpro_schema_tests).

-include_lib("eunit/include/eunit.hrl").

all_test() ->
  lists:foreach(fun test_api/1, kpro_schema:all_apis()).

test_api(API) ->
  ?assertEqual(API, kpro_schema:api_key(kpro_schema:api_key(API))),
  {MinV, MaxV} = kpro_schema:vsn_range(API),
  lists:foreach(fun(V) ->
                    ?assert(is_list(kpro_schema:req(API, V))),
                    ?assert(is_list(kpro_schema:rsp(API, V)))
                end, lists:seq(MinV, MaxV)).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
