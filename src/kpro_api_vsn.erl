%% generated code, do not edit!
-module(kpro_api_vsn).
-export([range/1]).

range(produce) -> {0, 5};
range(fetch) -> {0, 6};
range(list_offsets) -> {0, 2};
range(metadata) -> {0, 5};
range(leader_and_isr) -> {0, 1};
range(stop_replica) -> {0, 0};
range(update_metadata) -> {0, 4};
range(controlled_shutdown) -> {0, 1};
range(offset_commit) -> {0, 3};
range(offset_fetch) -> {0, 3};
range(find_coordinator) -> {0, 1};
range(join_group) -> {0, 2};
range(heartbeat) -> {0, 1};
range(leave_group) -> {0, 1};
range(sync_group) -> {0, 1};
range(describe_groups) -> {0, 1};
range(list_groups) -> {0, 1};
range(sasl_handshake) -> {0, 1};
range(api_versions) -> {0, 1};
range(create_topics) -> {0, 2};
range(delete_topics) -> {0, 1};
range(delete_records) -> {0, 0};
range(init_producer_id) -> {0, 0};
range(offset_for_leader_epoch) -> {0, 0};
range(add_partitions_to_txn) -> {0, 0};
range(add_offsets_to_txn) -> {0, 0};
range(end_txn) -> {0, 0};
range(write_txn_markers) -> {0, 0};
range(txn_offset_commit) -> {0, 0};
range(describe_acls) -> {0, 0};
range(create_acls) -> {0, 0};
range(delete_acls) -> {0, 0};
range(describe_configs) -> {0, 0};
range(alter_configs) -> {0, 0};
range(alter_replica_log_dirs) -> {0, 0};
range(describe_log_dirs) -> {0, 0};
range(sasl_authenticate) -> {0, 0};
range(create_partitions) -> {0, 0}.

