* 0.9 -> 1.0 incompatible changes
  - changed from erlang.mk to rebar/rebar3
  - encode inputs from records to proplists
  - decode ouptuts from records to proplists
  - `kpro:fetch_request`, `kpro:offsets_request` APIs have args list changed
  - Maximum correlation ID changed to (1 bsl 24 - 1)

* 1.0.1 Added more type exports
* 1.1.0
  - Bug Fixes:
      * Adding missing error code and add api-key interpretation
  - New Features
      * Support message timestamp in message-set encoding input `{Ts, Key, Value}`
