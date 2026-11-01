%% Legacy callback contract, without a handshake-version argument.
-module(kpro_compatibility_callback).
-export([auth/6]).
auth(_Host, _Sock, _Mod, ClientId, _Timeout, Owner) ->
  Owner ! {callback6, ClientId},
  {ok, #{session_lifetime_ms => 0}}.
