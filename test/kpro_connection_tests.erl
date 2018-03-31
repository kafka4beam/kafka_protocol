-module(kpro_connection_tests).

-include_lib("eunit/include/eunit.hrl").

ssl_test() ->
  ok.
  % Config = #{ssl => ssl_options()},
  % {ok, Pid} = connect(Config),
  % ok = kpro_connection:stop(Pid).

sasl_test() ->
  Config = #{ ssl => ssl_options()
            , sasl => kpro_test_lib:sasl_config()
            },
  {ok, Pid} = connect(Config),
  ok = kpro_connection:stop(Pid).

sasl_file_test() ->
  Config = #{ ssl => ssl_options()
            , sasl => kpro_test_lib:sasl_config(file)
            },
  {ok, Pid} = connect(Config),
  ok = kpro_connection:stop(Pid).

no_api_version_query_test() ->
  Config = #{query_api_versions => false},
  {ok, Pid} = connect(Config),
  ?assertEqual({ok, undefined}, kpro_connection:get_api_vsns(Pid)),
  ok = kpro_connection:stop(Pid).

connect(Config) ->
  Protocol = kpro_test_lib:guess_protocol(Config),
  [{Host, Port} | _] = kpro_test_lib:get_endpoints(Protocol),
  kpro_connection:start(Host, Port, Config).

ssl_options() ->
  PrivDir = code:priv_dir(?APPLICATION),
  Fname = fun(Name) -> filename:join([PrivDir, ssl, Name]) end,
  [ {cacertfile, Fname("ca.crt")}
  , {keyfile,    Fname("client.key")}
  , {certfile,   Fname("client.crt")}
  ].

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
