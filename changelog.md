* 4.2.7

  - Upgrade crc32cer from 1.0.2 to 1.0.3 for better build speed.
    The new version avoids clone some unnecessary submodules.

* 4.2.6
   - Fix API version ranges. Test against Kafka 4.0.0

* 4.2.5
   - Upgrade to crc32cer-1.0.2 for cmake 4.x.
     There was a typo in app.src in crc32cer-1.0.1.

* 4.2.4
   - Upgrade to crc32cer-1.0.1 for better performance (on arm, 4.2.3 improved on x86).
     Now crc32c is calculated on dirty scheduler.
   - Another prerformance improvment (not verified though) is to create batch binary when encoding message,
     so crc32c nif code can directly inspect binary data (instead of iolist), also smaller term to send as Erlang message.

* 4.2.3
   - Upgrade to crc32cer-0.1.12 for better performance (on x86).

* 4.2.2 (merge 2.3.6.6)
   - Avoid crash logs when connection has to shutdown.

* 4.2.1
  - Allow `iodata()` for `zstd` compression (previously only `binary()`).

* 4.2.0
  - Add support for `zstd` compression codec.

* 4.1.10
  - Resolve timeout value for discover and connect
    - partition leader
    - consumer group coordinator
    - cluster controller
    Choose the greater value of connect timeout and request timeout.

* 4.1.9
  - Upgrade crc32cer to 0.1.11 for build issue fix on OTP 27.

* 4.1.8
  - Avoid generating crash-report when failed to write socket [PR#124](https://github.com/kafka4beam/kafka_protocol/pull/124)

* 4.1.7
  - Automatically re-authenticate before session lifetime expires if SASL
    authentication module returns `{ok, ServerResponse}` and ServerResponse
    contains a non-zero `session_timeout_ms`.
    [PR#122](https://github.com/kafka4beam/kafka_protocol/pull/122)

* 4.1.6
  - Fix docs. [PR#120](https://github.com/kafka4beam/kafka_protocol/pull/120)

* 4.1.5
  - Avoid raising `badmatch` exception when parsing SASL file which may lead to password leaking in crash logs.

* 4.1.4
  - Ignore space in comma-separated hosts string.
  - Add more detailed information when server returned API version range is not supported.

* 4.1.3
  - Bump snappyer dependency from 1.2.8 to 1.2.9 (supports GCC 13).
  - Fix scram auth client final message.

* 4.1.2
  - Allow passwords passed down to `kpro_connection` to be multiply
    nested functions, instead of considering at most a single layer.

* 4.1.1
   - Ported changes from EMQX's fork (based on 2.3.6) back to master branch
     - Included an pushback twards 'no_ack' callers. https://github.com/emqx/kafka_protocol/pull/1
   - Avoid crashing on decoding unknown error codes
   - Improve SNI (server_name_indication) config.
     - Prior to this change, SNI is auto-added only when SSL option
       'verify' is set to 'verify_peer'.
       This retriction is unnecessary, because SNI is a part of
       client-hello in the handshake, it does not have anything to do
       with server certificate (and hostname) verification.
     - The connection config is shared between bootstrap connection
       and partition leader connection.
       Using a static SNI may work for bootstrap connections but
       may then fail for partition leaders if they happen to be
       different hosts (which is always the case in confluent cloud).
       To fix it, we now allow users to use two special values for SNI:
       - auto: use the exact connecting host name (FQDN or IP)
       - none: do not use anything at all.
* 4.1.0
   - Added pass SASL version to kpro_auth_backend behaviour modules
   - The application ˋstartˋ method must return the `pid` of the top supervisor
* 4.0.3
   - Fix type spec for `hostname()` to include `inet:ip_address()`
* 4.0.2
   - Bug fix: empty bytes is encoded to `0`, but not `-1`
   - Respect `connect` API's timeout parameter as an overall timeout, rather not the timeout for each internal step
* 4.0.1
  - Swap test environment to match docker-compose setup from `brod`
  - Fix keys in delete_topics and tests to use the correct field names
* 4.0.0
  - Remove hard dependencies on snappyer and lz4b.
    See 'Compression Support' section in README for more details.
* 3.1.0
  - Experimental support for lz4 compression.
* 3.0.1
  - remove old rebar from app.src
* 3.0.0
  - API support for Kafka 2.4
    Non backward compatible changes in request/response struct field names.

    New Kafka APIs:
      - `offset_for_leader_epoch`
      - `elect_leaders`
      - `incremental_alter_configs`
      - `alter_partition_reassignments`
      - `list_partition_reassignments`
      - `offset_delete`

    New versions of old APIs:
      - `produce`: 6-8
      - `fetch`: 8-11
      - `list_offsets`: 3-5
      - `metadata`: 6-9
      - `offset_commit`: 4-8
      - `offset_fetch`: 4-6
      - `find_coordinator`: 2-3
      - `join_group`: 3-6
      - `heartbeat`: 2-4
      - `leave_group`: 2-4
      - `sync_group`: 2-4
      - `describe_groups`: 2-5
      - `list_groups`: 2-3
      - `api_versions`: 2-3
      - `create_topics`: 3-5
      - `delete_topics`: 2-4
      - `delete_records`: 1
      - `init_producer_id`: 1-2
      - `add_partitions_to_txn`: 1
      - `add_offsets_to_txn`: 1
      - `end_txn`: 1
      - `txn_offset_commit`: 1-2
      - `describe_acls`: 1
      - `create_acls`: 1
      - `delete_acls`: 1
      - `describe_configs`: 2
      - `alter_configs`: 1
      - `alter_replica_log_dirs`: 1
      - `describe_log_dirs`: 1
      - `sasl_authenticate`: 1
      - `create_partitions`: 1
      - `create_delegation_token`: 1-2
      - `renew_delegation_token`: 1
      - `expire_delegation_token`: 1
      - `describe_delegation_token`: 1
      - `delete_groups`: 1-2

    Changed Fields:
      - `fetch`:
        - `epoch` -> `session_epoch`
        - `topics[]`:
          - `partitions[]`:
            - `max_bytes` -> `partition_max_bytes`
        - `forgetten_topics_data` -> `forgotten_topics_data[]`:
          - `partitions[]`:
            - `max_bytes` -> `partition_max_bytes`
      - `metadata`:
        - `topics[]`:
          - `string` -> `[{name,string}]`
      - `offset_commit`:
        - `retention_time` -> `retention_time_ms`
        - `topics[]`:
          - `topic` -> `name`
          - `partitions[]`:
            - `partition` -> `partition_index`
            - `offset` -> `committed_offset`
            - `metadata` -> `committed_metadata`
      - `offset_fetch`:
        - `topics[]`:
          - `topic` -> `name`
          - `partitions` -> `partition_indexes[]`:
            - `[{partition,int32}]` -> `int32`
      - `find_coordinator`:
        - `coordinator_key` -> `key`
        - `coordinator_type` -> `key_type`
      - `join_group`:
        - `session_timeout` -> `session_timeout_ms`
        - `rebalance_timeout` -> `rebalance_timeout_ms`
        - `group_protocols` -> `protocols[]`:
          - `protocol_name` -> `name`
          - `protocol_metadata` -> `metadata`
      - `sync_group`:
        - `group_assignment` -> `assignments[]`:
          - `member_assignment` -> `assignment`
      - `describe_groups`:
        - `group_ids` -> `groups`
      - `create_topics`:
        - `create_topic_requests` -> `topics[]`:
          - `topic` -> `name`
          - `replica_assignment` -> `assignments[]`:
            - `partition` -> `partition_index`
            - `replicas` -> `broker_ids`
          - `config_entries` -> `configs[]`:
            - `config_name` -> `name`
            - `config_value` -> `value`
        - `timeout` -> `timeout_ms`
      - `delete_topics`:
        - `topics` -> `topic_names`
        - `timeout` -> `timeout_ms`
      - `txn_offset_commit`:
        - `topics[]`:
          - `topic` -> `name`
          - `partitions[]`:
            - `partition` -> `partition_index`
            - `offset` -> `committed_offset`
            - `metadata` -> `committed_metadata`
      - `sasl_authenticate`:
        - `sasl_auth_bytes` -> `auth_bytes`
      - `create_delegation_token`:
        - `renewers[]`:
          - `name` -> `principal_name`
        - `max_life_time` -> `max_lifetime_ms`
      - `renew_delegation_token`:
        - `renew_time_period` -> `renew_period_ms`
      - `expire_delegation_token`:
        - `expiry_time_period` -> `expiry_time_period_ms`
      - `describe_delegation_token`:
        - `owners[]`:
          - `name` -> `principal_name`
      - `delete_groups`:
        - `groups` -> `groups_names`

* 2.4.1
  - Upgrade snappyer (1.2.6) and crc32cer (0.1.8):
    no need to link erl_interface for nif build
    erl_interface has been deprecated in otp 22 and will be deleted in 23

* 2.4.0
  - Add Describe and Alter Configs APIs, part of KIP-133

* 2.3.6
  - Upgrade snappyer and crc32cer to fix build in windows

* 2.3.5
  - Improve produce request encoding performance by 35%

* 2.3.4
  - Insert sni only when missing in ssl options
  - Ensure string() type sni in ssl options

* 2.3.3
  - consumer group message metadata V3

* 2.3.2
  - Made send_error Reason more informative

* 2.3.1
  - Use git tag as a source of truth for the application version

* 2.3.0
  - Honor LogAppendTime when decoding messages

* 2.2.9
  - Allo atom as hostname because `inet:hostname() :: atom() | string().`

* 2.2.8
  - Discard replica_not_available (ReplicaNotAvailable) in partition metadata

* 2.2.7
  - Improve varint encoding performance

* 2.2.6
  - Change kpro_lib:data_size/1 to iolist_size nif

* 2.2.5
  - Add `{server_name_indication, Host}` when `{verify, verify_peer}` is
    used. This is necessary for OTP >= 20.x.

* 2.2.4
  - Fix type specs (PR #48, by Piotr Bober)

* 2.2.3
  - Gotten rid of OS native timestamps

* 2.2.2
  - Moved make_ref to function impl from record definition

* 2.2.0
  - Add truly async send API `kpro:send/2`

* 2.1.2
  - Bump crc32cer to 0.1.3 to support alpine/busybox build

* 2.1.1
  - Pull docker image (instead of build locally) for tests
  - Update snappyer and crc32cer to support configurable nif so file lookup location

* 2.1.0
  - Simplify batch input. Batch magic version is derived from produce API version.
    no longer depends on batch input format to determine magic version.

* 2.0.1
  - Bump `crc32cer` to from `0.1.0` to `0.1.1` to fix build issue in OSX

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
  - Add sasl-scram support

* 1.1.2
  - Fix compressed message wrapper timestamp handling, use the max ts in compressed batch
  - Fix wrapper message offset (always set to 0) to work with kafka 0.11
  - Fix snappy decompression, version 1 record (MagicByte=1) may not have java snappy packing

* 1.1.1
  - Fix relative offset encoding/decoding in compressed batches

* 1.1.0
  - Bug Fixes:
      * Adding missing error code and add api-key interpretation
  - New Features
      * Support message timestamp in message-set encoding input `{Ts, Key, Value}`

* 1.0.1 Added more type exports

* 0.9 -> 1.0 incompatible changes
  - changed from erlang.mk to rebar/rebar3
  - encode inputs from records to proplists
  - decode outputs from records to proplists
  - `kpro:fetch_request`, `kpro:offsets_request` APIs have args list changed
  - Maximum correlation ID changed to (1 bsl 24 - 1)
