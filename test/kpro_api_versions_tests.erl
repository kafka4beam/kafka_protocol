-module(kpro_api_versions_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro.hrl").

-define(WITH_CONN(Host, Port, Fun),
        fun() ->
            {ok, Pid} = connect(Host, Port, #{}),
            try
              Fun(Pid)
            after
              kpro_connection:stop(Pid)
            end
        end()).

-define(TIMEOUT, 5000).

api_versions_test() ->
  ?WITH_CONN("localhost", 9092,
  fun(Conn) ->
      Req = kpro:req(api_versions_request, 0, []),
      {ok, Rsp} = kpro_connection:request_sync(Conn, Req, ?TIMEOUT),
      ?assertMatch(#kpro_rsp{ tag = api_versions_response
                            , vsn = 0
                            , msg = [ {error_code, no_error}
                                    , {api_versions, _}
                                    ]}, Rsp)
  end).

connect(Host, Port, Options) ->
  kpro_connection:start(self(), Host, Port, Options).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
