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
  - Add truely async send API `kpro:send/2`

* 2.1.2
  - Bump crc32cer to 0.1.3 to support alpine/busybox build

* 2.1.1
  - Pull docker image (instead of build locally) for tests
  - Update snappyer and crc32cer to support configurable nif so file lookup location

* 2.1.0
  - Simplify batch input. Batch magic version is derived from produce API version.
    no longer depends on batch input format to determin magic version.

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
  - decode ouptuts from records to proplists
  - `kpro:fetch_request`, `kpro:offsets_request` APIs have args list changed
  - Maximum correlation ID changed to (1 bsl 24 - 1)

