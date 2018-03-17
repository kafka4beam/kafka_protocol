-module(kpro_test_lib).

-export([ with_connection/1
        , with_connection/2
        , with_connection/3
        ]).

with_connection(Fun) ->
  with_connection(_Options = #{}, Fun).

with_connection(Options, Fun) ->
  Endpoints =
    case os:getenv("KAFKA_SEED_HOSTS") of
      false -> [{"localhost", 9092}];
      ""    -> [{"localhost", 9092}];
      Str   -> kpro_lib:parse_endpoints(Str)
    end,
  with_connection(Endpoints, Options, Fun).

with_connection(Endpoints, Options, Fun) ->
  {ok, Pid} = kpro:connect_any(Endpoints, Options),
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
