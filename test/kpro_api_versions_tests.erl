-module(kpro_api_versions_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro.hrl").

-define(TIMEOUT, 5000).

api_versions_test() ->
  kpro_test_lib:with_connection(
  fun(Conn) ->
      Req = kpro_req_lib:make(api_versions_request, 0, []),
      {ok, Rsp} = kpro_connection:request_sync(Conn, Req, ?TIMEOUT),
      ?assertMatch(#kpro_rsp{ tag = api_versions_response
                            , vsn = 0
                            , msg = [ {error_code, no_error}
                                    , {api_versions, _}
                                    ]}, Rsp)
  end).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
