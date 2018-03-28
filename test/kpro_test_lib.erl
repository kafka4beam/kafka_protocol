-module(kpro_test_lib).

-export([ with_connection/1
        , with_connection/2
        , with_connection/3
        , with_connection/4
        ]).

-type conn() :: kpro_connection:connection().
-type config() :: kpro_connection:config().

-spec with_connection(fun((conn()) -> any())) -> any().
with_connection(WithConnFun) ->
  with_connection(fun kpro:connect_any/2, WithConnFun).

-spec with_connection(fun(([kpro:endpoint()], config()) -> {ok, conn()}),
                      fun((conn()) -> any())) -> any().
with_connection(ConnectFun, WithConnFun) ->
  with_connection(_Config = #{}, ConnectFun, WithConnFun).

with_connection(Config, ConnectFun, WithConnFun) ->
  Endpoints = get_endpoints(),
  with_connection(Endpoints, Config, ConnectFun, WithConnFun).

with_connection(Endpoints, Config, ConnectFun, WithConnFun) ->
  {ok, Pid} = ConnectFun(Endpoints, Config),
  with_connection_pid(Pid, WithConnFun).

%%%_* Internal functions =======================================================

get_endpoints() ->
  case os:getenv("KAFKA_SEED_HOSTS") of
    false -> [{"localhost", 9092}];
    ""    -> [{"localhost", 9092}];
    Str   -> kpro_lib:parse_endpoints(Str)
  end.

with_connection_pid(Pid, Fun) ->
  try
    Fun(Pid)
  after
    unlink(Pid),
    kpro_connection:stop(Pid)
  end.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
