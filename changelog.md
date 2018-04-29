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
* 1.1.1
  - Fix relative offset encoding/decoding in compressed batches
* 1.1.2
  - Fix compressed message wrapper timestamp handling, use the max ts in compressed batch
  - Fix wrapper message offset (always set to 0) to work with kafka 0.11
  - Fix snappy decompression, version 1 record (MagicByte=1) may not have java snappy packing
* 2.0.0
  - Supported kafka 1.1 protocol
  - API keys are generated from bnf
  - Error codes are generated from a eterm.
  - Schema getters changed from `get(API_request, Vsn)` to `req(API, Vsn)`,
    and `get(API_response, Vsn)` to `rsp(API, Vsn)`.
  - `kpro:struct()` is now a `map()`, but `list()` is still supported as encoder input
  - Added socket implementation `kpro_connection.erl` (a copy of `brod_sock.erl`).
  - Basic connection management APIs:
      * connect to any node in a give cluster
      * discover and connect partition-leader
      * discover and connect group-coordinator
      * discover and connect transactional-coordinator
      * discover and connect cluster-controller
  - Transactional RPC primitives `kpro:txn_xxx`
  - Changed socket option from `{packet, raw}` to `{packet, 4}`

