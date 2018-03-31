-module(kpro_test_lib).

-export([ get_endpoints/1
        , guess_protocol/1
        ]).

-export([ with_connection/1
        , with_connection/2
        , with_connection/3
        , with_connection/4
        ]).

-type conn() :: kpro_connection:connection().
-type config() :: kpro_connection:config().

get_endpoints(Protocol) ->
  case os:getenv("KAFKA_ENDPOINTS") of
    false -> default_endpoints(Protocol);
    ""    -> default_endpoints(Protocol);
    Str   -> kpro:parse_endpoints(Protocol, Str)
  end.

-spec with_connection(fun((conn()) -> any())) -> any().
with_connection(WithConnFun) ->
  with_connection(fun kpro:connect_any/2, WithConnFun).

-spec with_connection(fun(([kpro:endpoint()], config()) -> {ok, conn()}),
                      fun((conn()) -> any())) -> any().
with_connection(ConnectFun, WithConnFun) ->
  with_connection(_Config = #{}, ConnectFun, WithConnFun).

with_connection(Config, ConnectFun, WithConnFun) ->
  Endpoints = get_endpoints(guess_protocol(Config)),
  with_connection(Endpoints, Config, ConnectFun, WithConnFun).

with_connection(Endpoints, Config, ConnectFun, WithConnFun) ->
  {ok, Pid} = ConnectFun(Endpoints, Config),
  with_connection_pid(Pid, WithConnFun).

%% Guess protocol name from connection config.
guess_protocol(#{sasl := _}) -> sasl_ssl; %% we only test sasl on ssl
guess_protocol(#{ssl := false}) -> plaintext;
guess_protocol(#{ssl := _}) -> ssl;
guess_protocol(_) -> plaintext.

%%%_* Internal functions =======================================================

default_endpoints(plaintext) -> [{"localhost", 9092}];
default_endpoints(ssl) -> [{"localhost", 9093}];
default_endpoints(sasl_ssl) -> [{"localhost", 9094}].

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
