-module(kpro_connection_tests).

-include_lib("eunit/include/eunit.hrl").

ssl_test() ->
  Opts = #{ssl => ssl_options()},
  {ok, Pid} = connect("localhost", 9093, Opts),
  ok = kpro_connection:stop(Pid).

sasl_test() ->
  Opts = #{ ssl => ssl_options()
          , sasl => {plain, "alice", <<"alice-secret">>}
          },
  {ok, Pid} = connect(<<"localhost">>, 9094, Opts),
  ok = kpro_connection:stop(Pid).

sasl_file_test() ->
  {setup,
   fun() ->
      file:write_file("sasl-plain-user-pass-file", "alice\nalice-secret\n")
   end,
   fun(_) ->
       file:delete("sasl-plain-user-pass-file")
   end,
   fun() ->
      Opts = #{ ssl => ssl_options()
              , sasl => {plain, <<"sasl-plain-user-pass-file">>}
              },
      {ok, Pid} = connect("localhost", 9094, Opts),
      ok = kpro_connection:stop(Pid)
   end}.

connect(Host, Port, Options) ->
  kpro_connection:start(Host, Port, Options).

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
