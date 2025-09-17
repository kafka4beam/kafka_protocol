%% generated code, do not edit!
-module(kpro_schema).
-export([all_apis/0, vsn_range/1, min_flexible_vsn/1, api_key/1, req/2, rsp/2, ec/1]).

all_apis() ->
[produce,
fetch,
list_offsets,
metadata,
offset_commit,
offset_fetch,
find_coordinator,
join_group,
heartbeat,
leave_group,
sync_group,
describe_groups,
list_groups,
sasl_handshake,
api_versions,
create_topics,
delete_topics,
delete_records,
init_producer_id,
offset_for_leader_epoch,
add_partitions_to_txn,
add_offsets_to_txn,
end_txn,
txn_offset_commit,
describe_acls,
create_acls,
delete_acls,
describe_configs,
alter_configs,
alter_replica_log_dirs,
describe_log_dirs,
sasl_authenticate,
create_partitions,
create_delegation_token,
renew_delegation_token,
expire_delegation_token,
describe_delegation_token,
delete_groups,
elect_leaders,
incremental_alter_configs,
alter_partition_reassignments,
list_partition_reassignments,
offset_delete,
describe_client_quotas,
alter_client_quotas,
describe_user_scram_credentials,
alter_user_scram_credentials,
fetch_snapshot,
describe_cluster,
describe_producers,
unregister_broker,
describe_transactions,
list_transactions,
consumer_group_heartbeat,
consumer_group_describe,
controller_registration,
get_telemetry_subscriptions,
push_telemetry,
assign_replicas_to_dirs,
list_config_resources,
describe_topic_partitions,
share_group_heartbeat,
share_group_describe,
share_fetch,
share_acknowledge,
add_raft_voter,
remove_raft_voter,
update_raft_voter,
streams_group_heartbeat,
streams_group_describe,
describe_share_group_offsets,
alter_share_group_offsets,
delete_share_group_offsets].

min_flexible_vsn(produce) -> 9;
min_flexible_vsn(fetch) -> 12;
min_flexible_vsn(list_offsets) -> 6;
min_flexible_vsn(metadata) -> 9;
min_flexible_vsn(offset_commit) -> 8;
min_flexible_vsn(offset_fetch) -> 6;
min_flexible_vsn(find_coordinator) -> 3;
min_flexible_vsn(join_group) -> 6;
min_flexible_vsn(heartbeat) -> 4;
min_flexible_vsn(leave_group) -> 4;
min_flexible_vsn(sync_group) -> 4;
min_flexible_vsn(describe_groups) -> 5;
min_flexible_vsn(list_groups) -> 3;
min_flexible_vsn(api_versions) -> 3;
min_flexible_vsn(create_topics) -> 5;
min_flexible_vsn(delete_topics) -> 4;
min_flexible_vsn(delete_records) -> 2;
min_flexible_vsn(init_producer_id) -> 2;
min_flexible_vsn(offset_for_leader_epoch) -> 4;
min_flexible_vsn(add_partitions_to_txn) -> 3;
min_flexible_vsn(add_offsets_to_txn) -> 3;
min_flexible_vsn(end_txn) -> 3;
min_flexible_vsn(txn_offset_commit) -> 3;
min_flexible_vsn(describe_acls) -> 2;
min_flexible_vsn(create_acls) -> 2;
min_flexible_vsn(delete_acls) -> 2;
min_flexible_vsn(describe_configs) -> 4;
min_flexible_vsn(alter_configs) -> 2;
min_flexible_vsn(alter_replica_log_dirs) -> 2;
min_flexible_vsn(describe_log_dirs) -> 2;
min_flexible_vsn(sasl_authenticate) -> 2;
min_flexible_vsn(create_partitions) -> 2;
min_flexible_vsn(create_delegation_token) -> 2;
min_flexible_vsn(renew_delegation_token) -> 2;
min_flexible_vsn(expire_delegation_token) -> 2;
min_flexible_vsn(describe_delegation_token) -> 2;
min_flexible_vsn(delete_groups) -> 2;
min_flexible_vsn(elect_leaders) -> 2;
min_flexible_vsn(incremental_alter_configs) -> 1;
min_flexible_vsn(alter_partition_reassignments) -> 0;
min_flexible_vsn(list_partition_reassignments) -> 0;
min_flexible_vsn(describe_client_quotas) -> 1;
min_flexible_vsn(alter_client_quotas) -> 1;
min_flexible_vsn(describe_user_scram_credentials) -> 0;
min_flexible_vsn(alter_user_scram_credentials) -> 0;
min_flexible_vsn(fetch_snapshot) -> 0;
min_flexible_vsn(describe_cluster) -> 0;
min_flexible_vsn(describe_producers) -> 0;
min_flexible_vsn(unregister_broker) -> 0;
min_flexible_vsn(describe_transactions) -> 0;
min_flexible_vsn(list_transactions) -> 0;
min_flexible_vsn(consumer_group_heartbeat) -> 0;
min_flexible_vsn(consumer_group_describe) -> 0;
min_flexible_vsn(controller_registration) -> 0;
min_flexible_vsn(get_telemetry_subscriptions) -> 0;
min_flexible_vsn(push_telemetry) -> 0;
min_flexible_vsn(assign_replicas_to_dirs) -> 0;
min_flexible_vsn(list_config_resources) -> 0;
min_flexible_vsn(describe_topic_partitions) -> 0;
min_flexible_vsn(share_group_heartbeat) -> 1;
min_flexible_vsn(share_group_describe) -> 1;
min_flexible_vsn(share_fetch) -> 1;
min_flexible_vsn(share_acknowledge) -> 1;
min_flexible_vsn(add_raft_voter) -> 0;
min_flexible_vsn(remove_raft_voter) -> 0;
min_flexible_vsn(update_raft_voter) -> 0;
min_flexible_vsn(streams_group_heartbeat) -> 0;
min_flexible_vsn(streams_group_describe) -> 0;
min_flexible_vsn(describe_share_group_offsets) -> 0;
min_flexible_vsn(alter_share_group_offsets) -> 0;
min_flexible_vsn(delete_share_group_offsets) -> 0;
min_flexible_vsn(_) -> 9999.

vsn_range(produce) -> {3, 13};
vsn_range(fetch) -> {4, 18};
vsn_range(list_offsets) -> {1, 10};
vsn_range(metadata) -> {0, 13};
vsn_range(offset_commit) -> {2, 10};
vsn_range(offset_fetch) -> {1, 10};
vsn_range(find_coordinator) -> {0, 6};
vsn_range(join_group) -> {0, 9};
vsn_range(heartbeat) -> {0, 4};
vsn_range(leave_group) -> {0, 5};
vsn_range(sync_group) -> {0, 5};
vsn_range(describe_groups) -> {0, 6};
vsn_range(list_groups) -> {0, 5};
vsn_range(sasl_handshake) -> {0, 1};
vsn_range(api_versions) -> {0, 4};
vsn_range(create_topics) -> {2, 7};
vsn_range(delete_topics) -> {1, 6};
vsn_range(delete_records) -> {0, 2};
vsn_range(init_producer_id) -> {0, 6};
vsn_range(offset_for_leader_epoch) -> {2, 4};
vsn_range(add_partitions_to_txn) -> {0, 5};
vsn_range(add_offsets_to_txn) -> {0, 4};
vsn_range(end_txn) -> {0, 5};
vsn_range(txn_offset_commit) -> {0, 5};
vsn_range(describe_acls) -> {1, 3};
vsn_range(create_acls) -> {1, 3};
vsn_range(delete_acls) -> {1, 3};
vsn_range(describe_configs) -> {1, 4};
vsn_range(alter_configs) -> {0, 2};
vsn_range(alter_replica_log_dirs) -> {1, 2};
vsn_range(describe_log_dirs) -> {1, 4};
vsn_range(sasl_authenticate) -> {0, 2};
vsn_range(create_partitions) -> {0, 3};
vsn_range(create_delegation_token) -> {1, 3};
vsn_range(renew_delegation_token) -> {1, 2};
vsn_range(expire_delegation_token) -> {1, 2};
vsn_range(describe_delegation_token) -> {1, 3};
vsn_range(delete_groups) -> {0, 2};
vsn_range(elect_leaders) -> {0, 2};
vsn_range(incremental_alter_configs) -> {0, 1};
vsn_range(alter_partition_reassignments) -> {0, 1};
vsn_range(list_partition_reassignments) -> {0, 0};
vsn_range(offset_delete) -> {0, 0};
vsn_range(describe_client_quotas) -> {0, 1};
vsn_range(alter_client_quotas) -> {0, 1};
vsn_range(describe_user_scram_credentials) -> {0, 0};
vsn_range(alter_user_scram_credentials) -> {0, 0};
vsn_range(fetch_snapshot) -> {0, 1};
vsn_range(describe_cluster) -> {0, 2};
vsn_range(describe_producers) -> {0, 0};
vsn_range(unregister_broker) -> {0, 0};
vsn_range(describe_transactions) -> {0, 0};
vsn_range(list_transactions) -> {0, 2};
vsn_range(consumer_group_heartbeat) -> {0, 1};
vsn_range(consumer_group_describe) -> {0, 1};
vsn_range(controller_registration) -> {0, 0};
vsn_range(get_telemetry_subscriptions) -> {0, 0};
vsn_range(push_telemetry) -> {0, 0};
vsn_range(assign_replicas_to_dirs) -> {0, 0};
vsn_range(list_config_resources) -> {0, 1};
vsn_range(describe_topic_partitions) -> {0, 0};
vsn_range(share_group_heartbeat) -> {1, 1};
vsn_range(share_group_describe) -> {1, 1};
vsn_range(share_fetch) -> {1, 1};
vsn_range(share_acknowledge) -> {1, 1};
vsn_range(add_raft_voter) -> {0, 0};
vsn_range(remove_raft_voter) -> {0, 0};
vsn_range(update_raft_voter) -> {0, 0};
vsn_range(streams_group_heartbeat) -> {0, 0};
vsn_range(streams_group_describe) -> {0, 0};
vsn_range(describe_share_group_offsets) -> {0, 0};
vsn_range(alter_share_group_offsets) -> {0, 0};
vsn_range(delete_share_group_offsets) -> {0, 0};
vsn_range(_) -> false.

api_key(produce) -> 0;
api_key(0) -> produce;
api_key(fetch) -> 1;
api_key(1) -> fetch;
api_key(list_offsets) -> 2;
api_key(2) -> list_offsets;
api_key(metadata) -> 3;
api_key(3) -> metadata;
api_key(offset_commit) -> 8;
api_key(8) -> offset_commit;
api_key(offset_fetch) -> 9;
api_key(9) -> offset_fetch;
api_key(find_coordinator) -> 10;
api_key(10) -> find_coordinator;
api_key(join_group) -> 11;
api_key(11) -> join_group;
api_key(heartbeat) -> 12;
api_key(12) -> heartbeat;
api_key(leave_group) -> 13;
api_key(13) -> leave_group;
api_key(sync_group) -> 14;
api_key(14) -> sync_group;
api_key(describe_groups) -> 15;
api_key(15) -> describe_groups;
api_key(list_groups) -> 16;
api_key(16) -> list_groups;
api_key(sasl_handshake) -> 17;
api_key(17) -> sasl_handshake;
api_key(api_versions) -> 18;
api_key(18) -> api_versions;
api_key(create_topics) -> 19;
api_key(19) -> create_topics;
api_key(delete_topics) -> 20;
api_key(20) -> delete_topics;
api_key(delete_records) -> 21;
api_key(21) -> delete_records;
api_key(init_producer_id) -> 22;
api_key(22) -> init_producer_id;
api_key(offset_for_leader_epoch) -> 23;
api_key(23) -> offset_for_leader_epoch;
api_key(add_partitions_to_txn) -> 24;
api_key(24) -> add_partitions_to_txn;
api_key(add_offsets_to_txn) -> 25;
api_key(25) -> add_offsets_to_txn;
api_key(end_txn) -> 26;
api_key(26) -> end_txn;
api_key(txn_offset_commit) -> 28;
api_key(28) -> txn_offset_commit;
api_key(describe_acls) -> 29;
api_key(29) -> describe_acls;
api_key(create_acls) -> 30;
api_key(30) -> create_acls;
api_key(delete_acls) -> 31;
api_key(31) -> delete_acls;
api_key(describe_configs) -> 32;
api_key(32) -> describe_configs;
api_key(alter_configs) -> 33;
api_key(33) -> alter_configs;
api_key(alter_replica_log_dirs) -> 34;
api_key(34) -> alter_replica_log_dirs;
api_key(describe_log_dirs) -> 35;
api_key(35) -> describe_log_dirs;
api_key(sasl_authenticate) -> 36;
api_key(36) -> sasl_authenticate;
api_key(create_partitions) -> 37;
api_key(37) -> create_partitions;
api_key(create_delegation_token) -> 38;
api_key(38) -> create_delegation_token;
api_key(renew_delegation_token) -> 39;
api_key(39) -> renew_delegation_token;
api_key(expire_delegation_token) -> 40;
api_key(40) -> expire_delegation_token;
api_key(describe_delegation_token) -> 41;
api_key(41) -> describe_delegation_token;
api_key(delete_groups) -> 42;
api_key(42) -> delete_groups;
api_key(elect_leaders) -> 43;
api_key(43) -> elect_leaders;
api_key(incremental_alter_configs) -> 44;
api_key(44) -> incremental_alter_configs;
api_key(alter_partition_reassignments) -> 45;
api_key(45) -> alter_partition_reassignments;
api_key(list_partition_reassignments) -> 46;
api_key(46) -> list_partition_reassignments;
api_key(offset_delete) -> 47;
api_key(47) -> offset_delete;
api_key(describe_client_quotas) -> 48;
api_key(48) -> describe_client_quotas;
api_key(alter_client_quotas) -> 49;
api_key(49) -> alter_client_quotas;
api_key(describe_user_scram_credentials) -> 50;
api_key(50) -> describe_user_scram_credentials;
api_key(alter_user_scram_credentials) -> 51;
api_key(51) -> alter_user_scram_credentials;
api_key(fetch_snapshot) -> 59;
api_key(59) -> fetch_snapshot;
api_key(describe_cluster) -> 60;
api_key(60) -> describe_cluster;
api_key(describe_producers) -> 61;
api_key(61) -> describe_producers;
api_key(unregister_broker) -> 64;
api_key(64) -> unregister_broker;
api_key(describe_transactions) -> 65;
api_key(65) -> describe_transactions;
api_key(list_transactions) -> 66;
api_key(66) -> list_transactions;
api_key(consumer_group_heartbeat) -> 68;
api_key(68) -> consumer_group_heartbeat;
api_key(consumer_group_describe) -> 69;
api_key(69) -> consumer_group_describe;
api_key(controller_registration) -> 70;
api_key(70) -> controller_registration;
api_key(get_telemetry_subscriptions) -> 71;
api_key(71) -> get_telemetry_subscriptions;
api_key(push_telemetry) -> 72;
api_key(72) -> push_telemetry;
api_key(assign_replicas_to_dirs) -> 73;
api_key(73) -> assign_replicas_to_dirs;
api_key(list_config_resources) -> 74;
api_key(74) -> list_config_resources;
api_key(describe_topic_partitions) -> 75;
api_key(75) -> describe_topic_partitions;
api_key(share_group_heartbeat) -> 76;
api_key(76) -> share_group_heartbeat;
api_key(share_group_describe) -> 77;
api_key(77) -> share_group_describe;
api_key(share_fetch) -> 78;
api_key(78) -> share_fetch;
api_key(share_acknowledge) -> 79;
api_key(79) -> share_acknowledge;
api_key(add_raft_voter) -> 80;
api_key(80) -> add_raft_voter;
api_key(remove_raft_voter) -> 81;
api_key(81) -> remove_raft_voter;
api_key(update_raft_voter) -> 82;
api_key(82) -> update_raft_voter;
api_key(streams_group_heartbeat) -> 88;
api_key(88) -> streams_group_heartbeat;
api_key(streams_group_describe) -> 89;
api_key(89) -> streams_group_describe;
api_key(describe_share_group_offsets) -> 90;
api_key(90) -> describe_share_group_offsets;
api_key(alter_share_group_offsets) -> 91;
api_key(91) -> alter_share_group_offsets;
api_key(delete_share_group_offsets) -> 92;
api_key(92) -> delete_share_group_offsets;
api_key(API) -> erlang:error({not_supported, API}).

req(produce, V) when V >= 3, V =< 8 ->
  [{transactional_id,nullable_string},
   {acks,int16},
   {timeout_ms,int32},
   {topic_data,
       {array,
           [{name,string},
            {partition_data,{array,[{index,int32},{records,records}]}}]}}];
req(produce, V) when V >= 9, V =< 12 ->
  [{transactional_id,compact_nullable_string},
   {acks,int16},
   {timeout_ms,int32},
   {topic_data,
       {compact_array,
           [{name,compact_string},
            {partition_data,
                {compact_array,
                    [{index,int32},
                     {records,compact_records},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(produce, 13) ->
  [{transactional_id,compact_nullable_string},
   {acks,int16},
   {timeout_ms,int32},
   {topic_data,
       {compact_array,
           [{topic_id,uuid},
            {partition_data,
                {compact_array,
                    [{index,int32},
                     {records,compact_records},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(fetch, 4) ->
  [{replica_id,int32},
   {max_wait_ms,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {isolation_level,int8},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {fetch_offset,int64},
                                       {partition_max_bytes,int32}]}}]}}];
req(fetch, V) when V >= 5, V =< 6 ->
  [{replica_id,int32},
   {max_wait_ms,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {isolation_level,int8},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {fetch_offset,int64},
                                       {log_start_offset,int64},
                                       {partition_max_bytes,int32}]}}]}}];
req(fetch, V) when V >= 7, V =< 8 ->
  [{replica_id,int32},
   {max_wait_ms,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {isolation_level,int8},
   {session_id,int32},
   {session_epoch,int32},
   {topics,
       {array,
           [{topic,string},
            {partitions,
                {array,
                    [{partition,int32},
                     {fetch_offset,int64},
                     {log_start_offset,int64},
                     {partition_max_bytes,int32}]}}]}},
   {forgotten_topics_data,
       {array,
           [{topic,string},
            {partitions,
                {array,
                    [{partition,int32},
                     {fetch_offset,int64},
                     {log_start_offset,int64},
                     {partition_max_bytes,int32}]}}]}}];
req(fetch, V) when V >= 9, V =< 10 ->
  [{replica_id,int32},
   {max_wait_ms,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {isolation_level,int8},
   {session_id,int32},
   {session_epoch,int32},
   {topics,
       {array,
           [{topic,string},
            {partitions,
                {array,
                    [{partition,int32},
                     {current_leader_epoch,int32},
                     {fetch_offset,int64},
                     {log_start_offset,int64},
                     {partition_max_bytes,int32}]}}]}},
   {forgotten_topics_data,
       {array,
           [{topic,string},
            {partitions,
                {array,
                    [{partition,int32},
                     {current_leader_epoch,int32},
                     {fetch_offset,int64},
                     {log_start_offset,int64},
                     {partition_max_bytes,int32}]}}]}}];
req(fetch, 11) ->
  [{replica_id,int32},
   {max_wait_ms,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {isolation_level,int8},
   {session_id,int32},
   {session_epoch,int32},
   {topics,
       {array,
           [{topic,string},
            {partitions,
                {array,
                    [{partition,int32},
                     {current_leader_epoch,int32},
                     {fetch_offset,int64},
                     {log_start_offset,int64},
                     {partition_max_bytes,int32}]}}]}},
   {forgotten_topics_data,
       {array,
           [{topic,string},
            {partitions,
                {array,
                    [{partition,int32},
                     {current_leader_epoch,int32},
                     {fetch_offset,int64},
                     {log_start_offset,int64},
                     {partition_max_bytes,int32}]}}]}},
   {rack_id,string}];
req(fetch, 12) ->
  [{replica_id,int32},
   {max_wait_ms,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {isolation_level,int8},
   {session_id,int32},
   {session_epoch,int32},
   {topics,
       {compact_array,
           [{topic,compact_string},
            {partitions,
                {compact_array,
                    [{partition,int32},
                     {current_leader_epoch,int32},
                     {fetch_offset,int64},
                     {last_fetched_epoch,int32},
                     {log_start_offset,int64},
                     {partition_max_bytes,int32},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {forgotten_topics_data,
       {compact_array,
           [{topic,compact_string},
            {partitions,
                {compact_array,
                    [{partition,int32},
                     {current_leader_epoch,int32},
                     {fetch_offset,int64},
                     {last_fetched_epoch,int32},
                     {log_start_offset,int64},
                     {partition_max_bytes,int32},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {rack_id,compact_string},
   {tagged_fields,tagged_fields}];
req(fetch, V) when V >= 13, V =< 14 ->
  [{replica_id,int32},
   {max_wait_ms,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {isolation_level,int8},
   {session_id,int32},
   {session_epoch,int32},
   {topics,
       {compact_array,
           [{topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition,int32},
                     {current_leader_epoch,int32},
                     {fetch_offset,int64},
                     {last_fetched_epoch,int32},
                     {log_start_offset,int64},
                     {partition_max_bytes,int32},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {forgotten_topics_data,
       {compact_array,
           [{topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition,int32},
                     {current_leader_epoch,int32},
                     {fetch_offset,int64},
                     {last_fetched_epoch,int32},
                     {log_start_offset,int64},
                     {partition_max_bytes,int32},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {rack_id,compact_string},
   {tagged_fields,tagged_fields}];
req(fetch, V) when V >= 15, V =< 18 ->
  [{max_wait_ms,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {isolation_level,int8},
   {session_id,int32},
   {session_epoch,int32},
   {topics,
       {compact_array,
           [{topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition,int32},
                     {current_leader_epoch,int32},
                     {fetch_offset,int64},
                     {last_fetched_epoch,int32},
                     {log_start_offset,int64},
                     {partition_max_bytes,int32},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {forgotten_topics_data,
       {compact_array,
           [{topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition,int32},
                     {current_leader_epoch,int32},
                     {fetch_offset,int64},
                     {last_fetched_epoch,int32},
                     {log_start_offset,int64},
                     {partition_max_bytes,int32},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {rack_id,compact_string},
   {tagged_fields,tagged_fields}];
req(list_offsets, 1) ->
  [{replica_id,int32},
   {topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {timestamp,int64}]}}]}}];
req(list_offsets, V) when V >= 2, V =< 3 ->
  [{replica_id,int32},
   {isolation_level,int8},
   {topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {timestamp,int64}]}}]}}];
req(list_offsets, V) when V >= 4, V =< 5 ->
  [{replica_id,int32},
   {isolation_level,int8},
   {topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {current_leader_epoch,int32},
                                       {timestamp,int64}]}}]}}];
req(list_offsets, V) when V >= 6, V =< 9 ->
  [{replica_id,int32},
   {isolation_level,int8},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {current_leader_epoch,int32},
                     {timestamp,int64},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(list_offsets, 10) ->
  [{replica_id,int32},
   {isolation_level,int8},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {current_leader_epoch,int32},
                     {timestamp,int64},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {timeout_ms,int32},
   {tagged_fields,tagged_fields}];
req(metadata, V) when V >= 0, V =< 3 ->
  [{topics,{array,[{name,string}]}}];
req(metadata, V) when V >= 4, V =< 7 ->
  [{topics,{array,[{name,string}]}},{allow_auto_topic_creation,boolean}];
req(metadata, 8) ->
  [{topics,{array,[{name,string}]}},
   {allow_auto_topic_creation,boolean},
   {include_cluster_authorized_operations,boolean},
   {include_topic_authorized_operations,boolean}];
req(metadata, 9) ->
  [{topics,{compact_array,[{name,compact_string},
                           {tagged_fields,tagged_fields}]}},
   {allow_auto_topic_creation,boolean},
   {include_cluster_authorized_operations,boolean},
   {include_topic_authorized_operations,boolean},
   {tagged_fields,tagged_fields}];
req(metadata, 10) ->
  [{topics,{compact_array,[{topic_id,uuid},
                           {name,compact_nullable_string},
                           {tagged_fields,tagged_fields}]}},
   {allow_auto_topic_creation,boolean},
   {include_cluster_authorized_operations,boolean},
   {include_topic_authorized_operations,boolean},
   {tagged_fields,tagged_fields}];
req(metadata, V) when V >= 11, V =< 13 ->
  [{topics,{compact_array,[{topic_id,uuid},
                           {name,compact_nullable_string},
                           {tagged_fields,tagged_fields}]}},
   {allow_auto_topic_creation,boolean},
   {include_topic_authorized_operations,boolean},
   {tagged_fields,tagged_fields}];
req(offset_commit, V) when V >= 2, V =< 4 ->
  [{group_id,string},
   {generation_id_or_member_epoch,int32},
   {member_id,string},
   {retention_time_ms,int64},
   {topics,
       {array,
           [{name,string},
            {partitions,
                {array,
                    [{partition_index,int32},
                     {committed_offset,int64},
                     {committed_metadata,nullable_string}]}}]}}];
req(offset_commit, 5) ->
  [{group_id,string},
   {generation_id_or_member_epoch,int32},
   {member_id,string},
   {topics,
       {array,
           [{name,string},
            {partitions,
                {array,
                    [{partition_index,int32},
                     {committed_offset,int64},
                     {committed_metadata,nullable_string}]}}]}}];
req(offset_commit, 6) ->
  [{group_id,string},
   {generation_id_or_member_epoch,int32},
   {member_id,string},
   {topics,
       {array,
           [{name,string},
            {partitions,
                {array,
                    [{partition_index,int32},
                     {committed_offset,int64},
                     {committed_leader_epoch,int32},
                     {committed_metadata,nullable_string}]}}]}}];
req(offset_commit, 7) ->
  [{group_id,string},
   {generation_id_or_member_epoch,int32},
   {member_id,string},
   {group_instance_id,nullable_string},
   {topics,
       {array,
           [{name,string},
            {partitions,
                {array,
                    [{partition_index,int32},
                     {committed_offset,int64},
                     {committed_leader_epoch,int32},
                     {committed_metadata,nullable_string}]}}]}}];
req(offset_commit, V) when V >= 8, V =< 9 ->
  [{group_id,compact_string},
   {generation_id_or_member_epoch,int32},
   {member_id,compact_string},
   {group_instance_id,compact_nullable_string},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {committed_offset,int64},
                     {committed_leader_epoch,int32},
                     {committed_metadata,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(offset_commit, 10) ->
  [{group_id,compact_string},
   {generation_id_or_member_epoch,int32},
   {member_id,compact_string},
   {group_instance_id,compact_nullable_string},
   {topics,
       {compact_array,
           [{topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {committed_offset,int64},
                     {committed_leader_epoch,int32},
                     {committed_metadata,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(offset_fetch, V) when V >= 1, V =< 5 ->
  [{group_id,string},
   {topics,{array,[{name,string},{partition_indexes,{array,int32}}]}}];
req(offset_fetch, 6) ->
  [{group_id,compact_string},
   {topics,{compact_array,[{name,compact_string},
                           {partition_indexes,{compact_array,int32}},
                           {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(offset_fetch, 7) ->
  [{group_id,compact_string},
   {topics,{compact_array,[{name,compact_string},
                           {partition_indexes,{compact_array,int32}},
                           {tagged_fields,tagged_fields}]}},
   {require_stable,boolean},
   {tagged_fields,tagged_fields}];
req(offset_fetch, 8) ->
  [{groups,
       {compact_array,
           [{group_id,compact_string},
            {topics,
                {compact_array,
                    [{name,compact_string},
                     {partition_indexes,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {require_stable,boolean},
   {tagged_fields,tagged_fields}];
req(offset_fetch, 9) ->
  [{groups,
       {compact_array,
           [{group_id,compact_string},
            {member_id,compact_nullable_string},
            {member_epoch,int32},
            {topics,
                {compact_array,
                    [{name,compact_string},
                     {partition_indexes,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {require_stable,boolean},
   {tagged_fields,tagged_fields}];
req(offset_fetch, 10) ->
  [{groups,
       {compact_array,
           [{group_id,compact_string},
            {member_id,compact_nullable_string},
            {member_epoch,int32},
            {topics,
                {compact_array,
                    [{topic_id,uuid},
                     {partition_indexes,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {require_stable,boolean},
   {tagged_fields,tagged_fields}];
req(find_coordinator, 0) ->
  [{key,string}];
req(find_coordinator, V) when V >= 1, V =< 2 ->
  [{key,string},{key_type,int8}];
req(find_coordinator, 3) ->
  [{key,compact_string},{key_type,int8},{tagged_fields,tagged_fields}];
req(find_coordinator, V) when V >= 4, V =< 6 ->
  [{key_type,int8},
   {coordinator_keys,{compact_array,compact_string}},
   {tagged_fields,tagged_fields}];
req(join_group, 0) ->
  [{group_id,string},
   {session_timeout_ms,int32},
   {member_id,string},
   {protocol_type,string},
   {protocols,{array,[{name,string},{metadata,bytes}]}}];
req(join_group, V) when V >= 1, V =< 4 ->
  [{group_id,string},
   {session_timeout_ms,int32},
   {rebalance_timeout_ms,int32},
   {member_id,string},
   {protocol_type,string},
   {protocols,{array,[{name,string},{metadata,bytes}]}}];
req(join_group, 5) ->
  [{group_id,string},
   {session_timeout_ms,int32},
   {rebalance_timeout_ms,int32},
   {member_id,string},
   {group_instance_id,nullable_string},
   {protocol_type,string},
   {protocols,{array,[{name,string},{metadata,bytes}]}}];
req(join_group, V) when V >= 6, V =< 7 ->
  [{group_id,compact_string},
   {session_timeout_ms,int32},
   {rebalance_timeout_ms,int32},
   {member_id,compact_string},
   {group_instance_id,compact_nullable_string},
   {protocol_type,compact_string},
   {protocols,{compact_array,[{name,compact_string},
                              {metadata,compact_bytes},
                              {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(join_group, V) when V >= 8, V =< 9 ->
  [{group_id,compact_string},
   {session_timeout_ms,int32},
   {rebalance_timeout_ms,int32},
   {member_id,compact_string},
   {group_instance_id,compact_nullable_string},
   {protocol_type,compact_string},
   {protocols,{compact_array,[{name,compact_string},
                              {metadata,compact_bytes},
                              {tagged_fields,tagged_fields}]}},
   {reason,compact_nullable_string},
   {tagged_fields,tagged_fields}];
req(heartbeat, V) when V >= 0, V =< 2 ->
  [{group_id,string},{generation_id,int32},{member_id,string}];
req(heartbeat, 3) ->
  [{group_id,string},
   {generation_id,int32},
   {member_id,string},
   {group_instance_id,nullable_string}];
req(heartbeat, 4) ->
  [{group_id,compact_string},
   {generation_id,int32},
   {member_id,compact_string},
   {group_instance_id,compact_nullable_string},
   {tagged_fields,tagged_fields}];
req(leave_group, V) when V >= 0, V =< 2 ->
  [{group_id,string},{member_id,string}];
req(leave_group, 3) ->
  [{group_id,string},
   {members,{array,[{member_id,string},{group_instance_id,nullable_string}]}}];
req(leave_group, 4) ->
  [{group_id,compact_string},
   {members,{compact_array,[{member_id,compact_string},
                            {group_instance_id,compact_nullable_string},
                            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(leave_group, 5) ->
  [{group_id,compact_string},
   {members,{compact_array,[{member_id,compact_string},
                            {group_instance_id,compact_nullable_string},
                            {reason,compact_nullable_string},
                            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(sync_group, V) when V >= 0, V =< 2 ->
  [{group_id,string},
   {generation_id,int32},
   {member_id,string},
   {assignments,{array,[{member_id,string},{assignment,bytes}]}}];
req(sync_group, 3) ->
  [{group_id,string},
   {generation_id,int32},
   {member_id,string},
   {group_instance_id,nullable_string},
   {assignments,{array,[{member_id,string},{assignment,bytes}]}}];
req(sync_group, 4) ->
  [{group_id,compact_string},
   {generation_id,int32},
   {member_id,compact_string},
   {group_instance_id,compact_nullable_string},
   {assignments,{compact_array,[{member_id,compact_string},
                                {assignment,compact_bytes},
                                {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(sync_group, 5) ->
  [{group_id,compact_string},
   {generation_id,int32},
   {member_id,compact_string},
   {group_instance_id,compact_nullable_string},
   {protocol_type,compact_nullable_string},
   {protocol_name,compact_nullable_string},
   {assignments,{compact_array,[{member_id,compact_string},
                                {assignment,compact_bytes},
                                {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(describe_groups, V) when V >= 0, V =< 2 ->
  [{groups,{array,string}}];
req(describe_groups, V) when V >= 3, V =< 4 ->
  [{groups,{array,string}},{include_authorized_operations,boolean}];
req(describe_groups, V) when V >= 5, V =< 6 ->
  [{groups,{compact_array,compact_string}},
   {include_authorized_operations,boolean},
   {tagged_fields,tagged_fields}];
req(list_groups, V) when V >= 0, V =< 2 ->
  [];
req(list_groups, 3) ->
  [{tagged_fields,tagged_fields}];
req(list_groups, 4) ->
  [{states_filter,{compact_array,compact_string}},
   {tagged_fields,tagged_fields}];
req(list_groups, 5) ->
  [{states_filter,{compact_array,compact_string}},
   {types_filter,{compact_array,compact_string}},
   {tagged_fields,tagged_fields}];
req(sasl_handshake, V) when V >= 0, V =< 1 ->
  [{mechanism,string}];
req(api_versions, V) when V >= 0, V =< 2 ->
  [];
req(api_versions, V) when V >= 3, V =< 4 ->
  [{client_software_name,compact_string},
   {client_software_version,compact_string},
   {tagged_fields,tagged_fields}];
req(create_topics, V) when V >= 2, V =< 4 ->
  [{topics,
       {array,
           [{name,string},
            {num_partitions,int32},
            {replication_factor,int16},
            {assignments,
                {array,[{partition_index,int32},{broker_ids,{array,int32}}]}},
            {configs,{array,[{name,string},{value,nullable_string}]}}]}},
   {timeout_ms,int32},
   {validate_only,boolean}];
req(create_topics, V) when V >= 5, V =< 7 ->
  [{topics,
       {compact_array,
           [{name,compact_string},
            {num_partitions,int32},
            {replication_factor,int16},
            {assignments,
                {compact_array,
                    [{partition_index,int32},
                     {broker_ids,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {configs,
                {compact_array,
                    [{name,compact_string},
                     {value,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {timeout_ms,int32},
   {validate_only,boolean},
   {tagged_fields,tagged_fields}];
req(delete_topics, V) when V >= 1, V =< 3 ->
  [{topic_names,{array,string}},{timeout_ms,int32}];
req(delete_topics, V) when V >= 4, V =< 5 ->
  [{topic_names,{compact_array,compact_string}},
   {timeout_ms,int32},
   {tagged_fields,tagged_fields}];
req(delete_topics, 6) ->
  [{topics,{compact_array,[{name,compact_nullable_string},
                           {topic_id,uuid},
                           {tagged_fields,tagged_fields}]}},
   {timeout_ms,int32},
   {tagged_fields,tagged_fields}];
req(delete_records, V) when V >= 0, V =< 1 ->
  [{topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {offset,int64}]}}]}},
   {timeout_ms,int32}];
req(delete_records, 2) ->
  [{topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {offset,int64},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {timeout_ms,int32},
   {tagged_fields,tagged_fields}];
req(init_producer_id, V) when V >= 0, V =< 1 ->
  [{transactional_id,nullable_string},{transaction_timeout_ms,int32}];
req(init_producer_id, 2) ->
  [{transactional_id,compact_nullable_string},
   {transaction_timeout_ms,int32},
   {tagged_fields,tagged_fields}];
req(init_producer_id, V) when V >= 3, V =< 5 ->
  [{transactional_id,compact_nullable_string},
   {transaction_timeout_ms,int32},
   {producer_id,int64},
   {producer_epoch,int16},
   {tagged_fields,tagged_fields}];
req(init_producer_id, 6) ->
  [{transactional_id,compact_nullable_string},
   {transaction_timeout_ms,int32},
   {producer_id,int64},
   {producer_epoch,int16},
   {enable2_pc,boolean},
   {keep_prepared_txn,boolean},
   {tagged_fields,tagged_fields}];
req(offset_for_leader_epoch, 2) ->
  [{topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {current_leader_epoch,int32},
                                       {leader_epoch,int32}]}}]}}];
req(offset_for_leader_epoch, 3) ->
  [{replica_id,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {current_leader_epoch,int32},
                                       {leader_epoch,int32}]}}]}}];
req(offset_for_leader_epoch, 4) ->
  [{replica_id,int32},
   {topics,
       {compact_array,
           [{topic,compact_string},
            {partitions,
                {compact_array,
                    [{partition,int32},
                     {current_leader_epoch,int32},
                     {leader_epoch,int32},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(add_partitions_to_txn, V) when V >= 0, V =< 2 ->
  [{transactional_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {topics,{array,[{name,string},{partitions,{array,int32}}]}}];
req(add_partitions_to_txn, 3) ->
  [{transactional_id,compact_string},
   {producer_id,int64},
   {producer_epoch,int16},
   {topics,{compact_array,[{name,compact_string},
                           {partitions,{compact_array,int32}},
                           {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(add_partitions_to_txn, V) when V >= 4, V =< 5 ->
  [{transactions,
       {compact_array,
           [{transactional_id,compact_string},
            {producer_id,int64},
            {producer_epoch,int16},
            {verify_only,boolean},
            {topics,
                {compact_array,
                    [{name,compact_string},
                     {partitions,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(add_offsets_to_txn, V) when V >= 0, V =< 2 ->
  [{transactional_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {group_id,string}];
req(add_offsets_to_txn, V) when V >= 3, V =< 4 ->
  [{transactional_id,compact_string},
   {producer_id,int64},
   {producer_epoch,int16},
   {group_id,compact_string},
   {tagged_fields,tagged_fields}];
req(end_txn, V) when V >= 0, V =< 2 ->
  [{transactional_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {committed,boolean}];
req(end_txn, V) when V >= 3, V =< 5 ->
  [{transactional_id,compact_string},
   {producer_id,int64},
   {producer_epoch,int16},
   {committed,boolean},
   {tagged_fields,tagged_fields}];
req(txn_offset_commit, V) when V >= 0, V =< 1 ->
  [{transactional_id,string},
   {group_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {topics,
       {array,
           [{name,string},
            {partitions,
                {array,
                    [{partition_index,int32},
                     {committed_offset,int64},
                     {committed_metadata,nullable_string}]}}]}}];
req(txn_offset_commit, 2) ->
  [{transactional_id,string},
   {group_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {topics,
       {array,
           [{name,string},
            {partitions,
                {array,
                    [{partition_index,int32},
                     {committed_offset,int64},
                     {committed_leader_epoch,int32},
                     {committed_metadata,nullable_string}]}}]}}];
req(txn_offset_commit, V) when V >= 3, V =< 5 ->
  [{transactional_id,compact_string},
   {group_id,compact_string},
   {producer_id,int64},
   {producer_epoch,int16},
   {generation_id,int32},
   {member_id,compact_string},
   {group_instance_id,compact_nullable_string},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {committed_offset,int64},
                     {committed_leader_epoch,int32},
                     {committed_metadata,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(describe_acls, 1) ->
  [{resource_type_filter,int8},
   {resource_name_filter,nullable_string},
   {pattern_type_filter,int8},
   {principal_filter,nullable_string},
   {host_filter,nullable_string},
   {operation,int8},
   {permission_type,int8}];
req(describe_acls, V) when V >= 2, V =< 3 ->
  [{resource_type_filter,int8},
   {resource_name_filter,compact_nullable_string},
   {pattern_type_filter,int8},
   {principal_filter,compact_nullable_string},
   {host_filter,compact_nullable_string},
   {operation,int8},
   {permission_type,int8},
   {tagged_fields,tagged_fields}];
req(create_acls, 1) ->
  [{creations,{array,[{resource_type,int8},
                      {resource_name,string},
                      {resource_pattern_type,int8},
                      {principal,string},
                      {host,string},
                      {operation,int8},
                      {permission_type,int8}]}}];
req(create_acls, V) when V >= 2, V =< 3 ->
  [{creations,{compact_array,[{resource_type,int8},
                              {resource_name,compact_string},
                              {resource_pattern_type,int8},
                              {principal,compact_string},
                              {host,compact_string},
                              {operation,int8},
                              {permission_type,int8},
                              {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(delete_acls, 1) ->
  [{filters,{array,[{resource_type_filter,int8},
                    {resource_name_filter,nullable_string},
                    {pattern_type_filter,int8},
                    {principal_filter,nullable_string},
                    {host_filter,nullable_string},
                    {operation,int8},
                    {permission_type,int8}]}}];
req(delete_acls, V) when V >= 2, V =< 3 ->
  [{filters,{compact_array,[{resource_type_filter,int8},
                            {resource_name_filter,compact_nullable_string},
                            {pattern_type_filter,int8},
                            {principal_filter,compact_nullable_string},
                            {host_filter,compact_nullable_string},
                            {operation,int8},
                            {permission_type,int8},
                            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(describe_configs, V) when V >= 1, V =< 2 ->
  [{resources,{array,[{resource_type,int8},
                      {resource_name,string},
                      {configuration_keys,{array,string}}]}},
   {include_synonyms,boolean}];
req(describe_configs, 3) ->
  [{resources,{array,[{resource_type,int8},
                      {resource_name,string},
                      {configuration_keys,{array,string}}]}},
   {include_synonyms,boolean},
   {include_documentation,boolean}];
req(describe_configs, 4) ->
  [{resources,
       {compact_array,
           [{resource_type,int8},
            {resource_name,compact_string},
            {configuration_keys,{compact_array,compact_string}},
            {tagged_fields,tagged_fields}]}},
   {include_synonyms,boolean},
   {include_documentation,boolean},
   {tagged_fields,tagged_fields}];
req(alter_configs, V) when V >= 0, V =< 1 ->
  [{resources,{array,[{resource_type,int8},
                      {resource_name,string},
                      {configs,{array,[{name,string},
                                       {value,nullable_string}]}}]}},
   {validate_only,boolean}];
req(alter_configs, 2) ->
  [{resources,
       {compact_array,
           [{resource_type,int8},
            {resource_name,compact_string},
            {configs,
                {compact_array,
                    [{name,compact_string},
                     {value,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {validate_only,boolean},
   {tagged_fields,tagged_fields}];
req(alter_replica_log_dirs, 1) ->
  [{dirs,{array,[{path,string},
                 {topics,{array,[{name,string},
                                 {partitions,{array,int32}}]}}]}}];
req(alter_replica_log_dirs, 2) ->
  [{dirs,
       {compact_array,
           [{path,compact_string},
            {topics,
                {compact_array,
                    [{name,compact_string},
                     {partitions,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(describe_log_dirs, 1) ->
  [{topics,{array,[{topic,string},{partitions,{array,int32}}]}}];
req(describe_log_dirs, V) when V >= 2, V =< 4 ->
  [{topics,{compact_array,[{topic,compact_string},
                           {partitions,{compact_array,int32}},
                           {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(sasl_authenticate, V) when V >= 0, V =< 1 ->
  [{auth_bytes,bytes}];
req(sasl_authenticate, 2) ->
  [{auth_bytes,compact_bytes},{tagged_fields,tagged_fields}];
req(create_partitions, V) when V >= 0, V =< 1 ->
  [{topics,{array,[{name,string},
                   {count,int32},
                   {assignments,{array,[{broker_ids,{array,int32}}]}}]}},
   {timeout_ms,int32},
   {validate_only,boolean}];
req(create_partitions, V) when V >= 2, V =< 3 ->
  [{topics,
       {compact_array,
           [{name,compact_string},
            {count,int32},
            {assignments,
                {compact_array,
                    [{broker_ids,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {timeout_ms,int32},
   {validate_only,boolean},
   {tagged_fields,tagged_fields}];
req(create_delegation_token, 1) ->
  [{renewers,{array,[{principal_type,string},{principal_name,string}]}},
   {max_lifetime_ms,int64}];
req(create_delegation_token, 2) ->
  [{renewers,{compact_array,[{principal_type,compact_string},
                             {principal_name,compact_string},
                             {tagged_fields,tagged_fields}]}},
   {max_lifetime_ms,int64},
   {tagged_fields,tagged_fields}];
req(create_delegation_token, 3) ->
  [{owner_principal_type,compact_nullable_string},
   {owner_principal_name,compact_nullable_string},
   {renewers,{compact_array,[{principal_type,compact_string},
                             {principal_name,compact_string},
                             {tagged_fields,tagged_fields}]}},
   {max_lifetime_ms,int64},
   {tagged_fields,tagged_fields}];
req(renew_delegation_token, 1) ->
  [{hmac,bytes},{renew_period_ms,int64}];
req(renew_delegation_token, 2) ->
  [{hmac,compact_bytes},{renew_period_ms,int64},{tagged_fields,tagged_fields}];
req(expire_delegation_token, 1) ->
  [{hmac,bytes},{expiry_time_period_ms,int64}];
req(expire_delegation_token, 2) ->
  [{hmac,compact_bytes},
   {expiry_time_period_ms,int64},
   {tagged_fields,tagged_fields}];
req(describe_delegation_token, 1) ->
  [{owners,{array,[{principal_type,string},{principal_name,string}]}}];
req(describe_delegation_token, V) when V >= 2, V =< 3 ->
  [{owners,{compact_array,[{principal_type,compact_string},
                           {principal_name,compact_string},
                           {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(delete_groups, V) when V >= 0, V =< 1 ->
  [{groups_names,{array,string}}];
req(delete_groups, 2) ->
  [{groups_names,{compact_array,compact_string}},
   {tagged_fields,tagged_fields}];
req(elect_leaders, 0) ->
  [{topic_partitions,{array,[{topic,string},{partitions,{array,int32}}]}},
   {timeout_ms,int32}];
req(elect_leaders, 1) ->
  [{election_type,int8},
   {topic_partitions,{array,[{topic,string},{partitions,{array,int32}}]}},
   {timeout_ms,int32}];
req(elect_leaders, 2) ->
  [{election_type,int8},
   {topic_partitions,{compact_array,[{topic,compact_string},
                                     {partitions,{compact_array,int32}},
                                     {tagged_fields,tagged_fields}]}},
   {timeout_ms,int32},
   {tagged_fields,tagged_fields}];
req(incremental_alter_configs, 0) ->
  [{resources,{array,[{resource_type,int8},
                      {resource_name,string},
                      {configs,{array,[{name,string},
                                       {config_operation,int8},
                                       {value,nullable_string}]}}]}},
   {validate_only,boolean}];
req(incremental_alter_configs, 1) ->
  [{resources,
       {compact_array,
           [{resource_type,int8},
            {resource_name,compact_string},
            {configs,
                {compact_array,
                    [{name,compact_string},
                     {config_operation,int8},
                     {value,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {validate_only,boolean},
   {tagged_fields,tagged_fields}];
req(alter_partition_reassignments, 0) ->
  [{timeout_ms,int32},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {replicas,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(alter_partition_reassignments, 1) ->
  [{timeout_ms,int32},
   {allow_replication_factor_change,boolean},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {replicas,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(list_partition_reassignments, 0) ->
  [{timeout_ms,int32},
   {topics,{compact_array,[{name,compact_string},
                           {partition_indexes,{compact_array,int32}},
                           {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(offset_delete, 0) ->
  [{group_id,string},
   {topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32}]}}]}}];
req(describe_client_quotas, 0) ->
  [{components,{array,[{entity_type,string},
                       {match_type,int8},
                       {match,nullable_string}]}},
   {strict,boolean}];
req(describe_client_quotas, 1) ->
  [{components,{compact_array,[{entity_type,compact_string},
                               {match_type,int8},
                               {match,compact_nullable_string},
                               {tagged_fields,tagged_fields}]}},
   {strict,boolean},
   {tagged_fields,tagged_fields}];
req(alter_client_quotas, 0) ->
  [{entries,{array,[{entity,{array,[{entity_type,string},
                                    {entity_name,nullable_string}]}},
                    {ops,{array,[{key,string},
                                 {value,float64},
                                 {remove,boolean}]}}]}},
   {validate_only,boolean}];
req(alter_client_quotas, 1) ->
  [{entries,
       {compact_array,
           [{entity,
                {compact_array,
                    [{entity_type,compact_string},
                     {entity_name,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {ops,
                {compact_array,
                    [{key,compact_string},
                     {value,float64},
                     {remove,boolean},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {validate_only,boolean},
   {tagged_fields,tagged_fields}];
req(describe_user_scram_credentials, 0) ->
  [{users,{compact_array,[{name,compact_string},
                          {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(alter_user_scram_credentials, 0) ->
  [{deletions,{compact_array,[{name,compact_string},
                              {mechanism,int8},
                              {tagged_fields,tagged_fields}]}},
   {upsertions,{compact_array,[{name,compact_string},
                               {mechanism,int8},
                               {iterations,int32},
                               {salt,compact_bytes},
                               {salted_password,compact_bytes},
                               {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(fetch_snapshot, V) when V >= 0, V =< 1 ->
  [{replica_id,int32},
   {max_bytes,int32},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition,int32},
                     {current_leader_epoch,int32},
                     {snapshot_id,
                         [{end_offset,int64},
                          {epoch,int32},
                          {tagged_fields,tagged_fields}]},
                     {position,int64},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(describe_cluster, 0) ->
  [{include_cluster_authorized_operations,boolean},
   {tagged_fields,tagged_fields}];
req(describe_cluster, 1) ->
  [{include_cluster_authorized_operations,boolean},
   {endpoint_type,int8},
   {tagged_fields,tagged_fields}];
req(describe_cluster, 2) ->
  [{include_cluster_authorized_operations,boolean},
   {endpoint_type,int8},
   {include_fenced_brokers,boolean},
   {tagged_fields,tagged_fields}];
req(describe_producers, 0) ->
  [{topics,{compact_array,[{name,compact_string},
                           {partition_indexes,{compact_array,int32}},
                           {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(unregister_broker, 0) ->
  [{broker_id,int32},{tagged_fields,tagged_fields}];
req(describe_transactions, 0) ->
  [{transactional_ids,{compact_array,compact_string}},
   {tagged_fields,tagged_fields}];
req(list_transactions, 0) ->
  [{state_filters,{compact_array,compact_string}},
   {producer_id_filters,{compact_array,int64}},
   {tagged_fields,tagged_fields}];
req(list_transactions, 1) ->
  [{state_filters,{compact_array,compact_string}},
   {producer_id_filters,{compact_array,int64}},
   {duration_filter,int64},
   {tagged_fields,tagged_fields}];
req(list_transactions, 2) ->
  [{state_filters,{compact_array,compact_string}},
   {producer_id_filters,{compact_array,int64}},
   {duration_filter,int64},
   {transactional_id_pattern,compact_nullable_string},
   {tagged_fields,tagged_fields}];
req(consumer_group_heartbeat, 0) ->
  [{group_id,compact_string},
   {member_id,compact_string},
   {member_epoch,int32},
   {instance_id,compact_nullable_string},
   {rack_id,compact_nullable_string},
   {rebalance_timeout_ms,int32},
   {subscribed_topic_names,{compact_array,compact_string}},
   {server_assignor,compact_nullable_string},
   {topic_partitions,{compact_array,[{topic_id,uuid},
                                     {partitions,{compact_array,int32}},
                                     {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(consumer_group_heartbeat, 1) ->
  [{group_id,compact_string},
   {member_id,compact_string},
   {member_epoch,int32},
   {instance_id,compact_nullable_string},
   {rack_id,compact_nullable_string},
   {rebalance_timeout_ms,int32},
   {subscribed_topic_names,{compact_array,compact_string}},
   {subscribed_topic_regex,compact_nullable_string},
   {server_assignor,compact_nullable_string},
   {topic_partitions,{compact_array,[{topic_id,uuid},
                                     {partitions,{compact_array,int32}},
                                     {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(consumer_group_describe, V) when V >= 0, V =< 1 ->
  [{group_ids,{compact_array,compact_string}},
   {include_authorized_operations,boolean},
   {tagged_fields,tagged_fields}];
req(controller_registration, 0) ->
  [{controller_id,int32},
   {incarnation_id,uuid},
   {zk_migration_ready,boolean},
   {listeners,{compact_array,[{name,compact_string},
                              {host,compact_string},
                              {port,uint16},
                              {security_protocol,int16},
                              {tagged_fields,tagged_fields}]}},
   {features,{compact_array,[{name,compact_string},
                             {min_supported_version,int16},
                             {max_supported_version,int16},
                             {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(get_telemetry_subscriptions, 0) ->
  [{client_instance_id,uuid},{tagged_fields,tagged_fields}];
req(push_telemetry, 0) ->
  [{client_instance_id,uuid},
   {subscription_id,int32},
   {terminating,boolean},
   {compression_type,int8},
   {metrics,compact_bytes},
   {tagged_fields,tagged_fields}];
req(assign_replicas_to_dirs, 0) ->
  [{broker_id,int32},
   {broker_epoch,int64},
   {directories,
       {compact_array,
           [{id,uuid},
            {topics,
                {compact_array,
                    [{topic_id,uuid},
                     {partitions,
                         {compact_array,
                             [{partition_index,int32},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(list_config_resources, 0) ->
  [{tagged_fields,tagged_fields}];
req(list_config_resources, 1) ->
  [{resource_types,{compact_array,int8}},{tagged_fields,tagged_fields}];
req(describe_topic_partitions, 0) ->
  [{topics,{compact_array,[{name,compact_string},
                           {tagged_fields,tagged_fields}]}},
   {response_partition_limit,int32},
   {cursor,[{topic_name,compact_string},
            {partition_index,int32},
            {tagged_fields,tagged_fields}]},
   {tagged_fields,tagged_fields}];
req(share_group_heartbeat, 1) ->
  [{group_id,compact_string},
   {member_id,compact_string},
   {member_epoch,int32},
   {rack_id,compact_nullable_string},
   {subscribed_topic_names,{compact_array,compact_string}},
   {tagged_fields,tagged_fields}];
req(share_group_describe, 1) ->
  [{group_ids,{compact_array,compact_string}},
   {include_authorized_operations,boolean},
   {tagged_fields,tagged_fields}];
req(share_fetch, 1) ->
  [{group_id,compact_nullable_string},
   {member_id,compact_nullable_string},
   {share_session_epoch,int32},
   {max_wait_ms,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {max_records,int32},
   {batch_size,int32},
   {topics,
       {compact_array,
           [{topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {acknowledgement_batches,
                         {compact_array,
                             [{first_offset,int64},
                              {last_offset,int64},
                              {acknowledge_types,{compact_array,int8}},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {forgotten_topics_data,
       {compact_array,
           [{topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {acknowledgement_batches,
                         {compact_array,
                             [{first_offset,int64},
                              {last_offset,int64},
                              {acknowledge_types,{compact_array,int8}},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(share_acknowledge, 1) ->
  [{group_id,compact_nullable_string},
   {member_id,compact_nullable_string},
   {share_session_epoch,int32},
   {topics,
       {compact_array,
           [{topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {acknowledgement_batches,
                         {compact_array,
                             [{first_offset,int64},
                              {last_offset,int64},
                              {acknowledge_types,{compact_array,int8}},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(add_raft_voter, 0) ->
  [{cluster_id,compact_nullable_string},
   {timeout_ms,int32},
   {voter_id,int32},
   {voter_directory_id,uuid},
   {listeners,{compact_array,[{name,compact_string},
                              {host,compact_string},
                              {port,uint16},
                              {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(remove_raft_voter, 0) ->
  [{cluster_id,compact_nullable_string},
   {voter_id,int32},
   {voter_directory_id,uuid},
   {tagged_fields,tagged_fields}];
req(update_raft_voter, 0) ->
  [{cluster_id,compact_nullable_string},
   {current_leader_epoch,int32},
   {voter_id,int32},
   {voter_directory_id,uuid},
   {listeners,{compact_array,[{name,compact_string},
                              {host,compact_string},
                              {port,uint16},
                              {tagged_fields,tagged_fields}]}},
   {kraft_version_feature,[{min_supported_version,int16},
                           {max_supported_version,int16},
                           {tagged_fields,tagged_fields}]},
   {tagged_fields,tagged_fields}];
req(streams_group_heartbeat, 0) ->
  [{group_id,compact_string},
   {member_id,compact_string},
   {member_epoch,int32},
   {endpoint_information_epoch,int32},
   {instance_id,compact_nullable_string},
   {rack_id,compact_nullable_string},
   {rebalance_timeout_ms,int32},
   {topology,
    [{epoch,int32},
     {subtopologies,
      {compact_array,
       [{subtopology_id,compact_string},
        {source_topics,{compact_array,compact_string}},
        {source_topic_regex,{compact_array,compact_string}},
        {state_changelog_topics,
         {compact_array,
          [{name,compact_string},
           {partitions,int32},
           {replication_factor,int16},
           {topic_configs,
            {compact_array,
             [{key,compact_string},
              {value,compact_string},
              {tagged_fields,tagged_fields}]}},
           {tagged_fields,tagged_fields}]}},
        {repartition_sink_topics,{compact_array,compact_string}},
        {repartition_source_topics,
         {compact_array,
          [{name,compact_string},
           {partitions,int32},
           {replication_factor,int16},
           {topic_configs,
            {compact_array,
             [{key,compact_string},
              {value,compact_string},
              {tagged_fields,tagged_fields}]}},
           {tagged_fields,tagged_fields}]}},
        {copartition_groups,
         {compact_array,
          [{source_topics,{compact_array,compact_string}},
           {source_topic_regex,{compact_array,compact_string}},
           {repartition_source_topics,
            {compact_array,
             [{name,compact_string},
              {partitions,int32},
              {replication_factor,int16},
              {topic_configs,
               {compact_array,
                [{key,compact_string},
                 {value,compact_string},
                 {tagged_fields,tagged_fields}]}},
              {tagged_fields,tagged_fields}]}},
           {tagged_fields,tagged_fields}]}},
        {tagged_fields,tagged_fields}]}},
     {tagged_fields,tagged_fields}]},
   {active_tasks,
    {compact_array,
     [{subtopology_id,compact_string},
      {partitions,{compact_array,int32}},
      {tagged_fields,tagged_fields}]}},
   {standby_tasks,
    {compact_array,
     [{subtopology_id,compact_string},
      {partitions,{compact_array,int32}},
      {tagged_fields,tagged_fields}]}},
   {warmup_tasks,
    {compact_array,
     [{subtopology_id,compact_string},
      {partitions,{compact_array,int32}},
      {tagged_fields,tagged_fields}]}},
   {process_id,compact_nullable_string},
   {user_endpoint,
    [{host,compact_string},{port,uint16},{tagged_fields,tagged_fields}]},
   {client_tags,
    {compact_array,
     [{key,compact_string},
      {value,compact_string},
      {tagged_fields,tagged_fields}]}},
   {task_offsets,
    {compact_array,
     [{subtopology_id,compact_string},
      {partition,int32},
      {offset,int64},
      {tagged_fields,tagged_fields}]}},
   {task_end_offsets,
    {compact_array,
     [{subtopology_id,compact_string},
      {partition,int32},
      {offset,int64},
      {tagged_fields,tagged_fields}]}},
   {shutdown_application,boolean},
   {tagged_fields,tagged_fields}];
req(streams_group_describe, 0) ->
  [{group_ids,{compact_array,compact_string}},
   {include_authorized_operations,boolean},
   {tagged_fields,tagged_fields}];
req(describe_share_group_offsets, 0) ->
  [{groups,
       {compact_array,
           [{group_id,compact_string},
            {topics,
                {compact_array,
                    [{topic_name,compact_string},
                     {partitions,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(alter_share_group_offsets, 0) ->
  [{group_id,compact_string},
   {topics,
       {compact_array,
           [{topic_name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {start_offset,int64},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
req(delete_share_group_offsets, 0) ->
  [{group_id,compact_string},
   {topics,{compact_array,[{topic_name,compact_string},
                           {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}].

rsp(produce, V) when V >= 3, V =< 4 ->
  [{responses,
       {array,
           [{name,string},
            {partition_responses,
                {array,
                    [{index,int32},
                     {error_code,int16},
                     {base_offset,int64},
                     {log_append_time_ms,int64}]}}]}},
   {throttle_time_ms,int32}];
rsp(produce, V) when V >= 5, V =< 7 ->
  [{responses,
       {array,
           [{name,string},
            {partition_responses,
                {array,
                    [{index,int32},
                     {error_code,int16},
                     {base_offset,int64},
                     {log_append_time_ms,int64},
                     {log_start_offset,int64}]}}]}},
   {throttle_time_ms,int32}];
rsp(produce, 8) ->
  [{responses,
       {array,
           [{name,string},
            {partition_responses,
                {array,
                    [{index,int32},
                     {error_code,int16},
                     {base_offset,int64},
                     {log_append_time_ms,int64},
                     {log_start_offset,int64},
                     {record_errors,
                         {array,
                             [{batch_index,int32},
                              {batch_index_error_message,nullable_string}]}},
                     {error_message,nullable_string}]}}]}},
   {throttle_time_ms,int32}];
rsp(produce, V) when V >= 9, V =< 12 ->
  [{responses,
       {compact_array,
           [{name,compact_string},
            {partition_responses,
                {compact_array,
                    [{index,int32},
                     {error_code,int16},
                     {base_offset,int64},
                     {log_append_time_ms,int64},
                     {log_start_offset,int64},
                     {record_errors,
                         {compact_array,
                             [{batch_index,int32},
                              {batch_index_error_message,
                                  compact_nullable_string},
                              {tagged_fields,tagged_fields}]}},
                     {error_message,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {throttle_time_ms,int32},
   {tagged_fields,tagged_fields}];
rsp(produce, 13) ->
  [{responses,
       {compact_array,
           [{topic_id,uuid},
            {partition_responses,
                {compact_array,
                    [{index,int32},
                     {error_code,int16},
                     {base_offset,int64},
                     {log_append_time_ms,int64},
                     {log_start_offset,int64},
                     {record_errors,
                         {compact_array,
                             [{batch_index,int32},
                              {batch_index_error_message,
                                  compact_nullable_string},
                              {tagged_fields,tagged_fields}]}},
                     {error_message,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {throttle_time_ms,int32},
   {tagged_fields,tagged_fields}];
rsp(fetch, 4) ->
  [{throttle_time_ms,int32},
   {responses,
       {array,
           [{topic,string},
            {partitions,
                {array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {high_watermark,int64},
                     {last_stable_offset,int64},
                     {aborted_transactions,
                         {array,[{producer_id,int64},{first_offset,int64}]}},
                     {records,records}]}}]}}];
rsp(fetch, V) when V >= 5, V =< 6 ->
  [{throttle_time_ms,int32},
   {responses,
       {array,
           [{topic,string},
            {partitions,
                {array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {high_watermark,int64},
                     {last_stable_offset,int64},
                     {log_start_offset,int64},
                     {aborted_transactions,
                         {array,[{producer_id,int64},{first_offset,int64}]}},
                     {records,records}]}}]}}];
rsp(fetch, V) when V >= 7, V =< 10 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {session_id,int32},
   {responses,
       {array,
           [{topic,string},
            {partitions,
                {array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {high_watermark,int64},
                     {last_stable_offset,int64},
                     {log_start_offset,int64},
                     {aborted_transactions,
                         {array,[{producer_id,int64},{first_offset,int64}]}},
                     {records,records}]}}]}}];
rsp(fetch, 11) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {session_id,int32},
   {responses,
       {array,
           [{topic,string},
            {partitions,
                {array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {high_watermark,int64},
                     {last_stable_offset,int64},
                     {log_start_offset,int64},
                     {aborted_transactions,
                         {array,[{producer_id,int64},{first_offset,int64}]}},
                     {preferred_read_replica,int32},
                     {records,records}]}}]}}];
rsp(fetch, 12) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {session_id,int32},
   {responses,
       {compact_array,
           [{topic,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {high_watermark,int64},
                     {last_stable_offset,int64},
                     {log_start_offset,int64},
                     {aborted_transactions,
                         {compact_array,
                             [{producer_id,int64},
                              {first_offset,int64},
                              {tagged_fields,tagged_fields}]}},
                     {preferred_read_replica,int32},
                     {records,compact_records},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(fetch, V) when V >= 13, V =< 18 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {session_id,int32},
   {responses,
       {compact_array,
           [{topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {high_watermark,int64},
                     {last_stable_offset,int64},
                     {log_start_offset,int64},
                     {aborted_transactions,
                         {compact_array,
                             [{producer_id,int64},
                              {first_offset,int64},
                              {tagged_fields,tagged_fields}]}},
                     {preferred_read_replica,int32},
                     {records,compact_records},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(list_offsets, 1) ->
  [{topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {error_code,int16},
                                       {timestamp,int64},
                                       {offset,int64}]}}]}}];
rsp(list_offsets, V) when V >= 2, V =< 3 ->
  [{throttle_time_ms,int32},
   {topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {error_code,int16},
                                       {timestamp,int64},
                                       {offset,int64}]}}]}}];
rsp(list_offsets, V) when V >= 4, V =< 5 ->
  [{throttle_time_ms,int32},
   {topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {error_code,int16},
                                       {timestamp,int64},
                                       {offset,int64},
                                       {leader_epoch,int32}]}}]}}];
rsp(list_offsets, V) when V >= 6, V =< 10 ->
  [{throttle_time_ms,int32},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {timestamp,int64},
                     {offset,int64},
                     {leader_epoch,int32},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(metadata, 0) ->
  [{brokers,{array,[{node_id,int32},{host,string},{port,int32}]}},
   {topics,{array,[{error_code,int16},
                   {name,string},
                   {partitions,{array,[{error_code,int16},
                                       {partition_index,int32},
                                       {leader_id,int32},
                                       {replica_nodes,{array,int32}},
                                       {isr_nodes,{array,int32}}]}}]}}];
rsp(metadata, 1) ->
  [{brokers,{array,[{node_id,int32},
                    {host,string},
                    {port,int32},
                    {rack,nullable_string}]}},
   {controller_id,int32},
   {topics,{array,[{error_code,int16},
                   {name,string},
                   {is_internal,boolean},
                   {partitions,{array,[{error_code,int16},
                                       {partition_index,int32},
                                       {leader_id,int32},
                                       {replica_nodes,{array,int32}},
                                       {isr_nodes,{array,int32}}]}}]}}];
rsp(metadata, 2) ->
  [{brokers,{array,[{node_id,int32},
                    {host,string},
                    {port,int32},
                    {rack,nullable_string}]}},
   {cluster_id,nullable_string},
   {controller_id,int32},
   {topics,{array,[{error_code,int16},
                   {name,string},
                   {is_internal,boolean},
                   {partitions,{array,[{error_code,int16},
                                       {partition_index,int32},
                                       {leader_id,int32},
                                       {replica_nodes,{array,int32}},
                                       {isr_nodes,{array,int32}}]}}]}}];
rsp(metadata, V) when V >= 3, V =< 4 ->
  [{throttle_time_ms,int32},
   {brokers,{array,[{node_id,int32},
                    {host,string},
                    {port,int32},
                    {rack,nullable_string}]}},
   {cluster_id,nullable_string},
   {controller_id,int32},
   {topics,{array,[{error_code,int16},
                   {name,string},
                   {is_internal,boolean},
                   {partitions,{array,[{error_code,int16},
                                       {partition_index,int32},
                                       {leader_id,int32},
                                       {replica_nodes,{array,int32}},
                                       {isr_nodes,{array,int32}}]}}]}}];
rsp(metadata, V) when V >= 5, V =< 6 ->
  [{throttle_time_ms,int32},
   {brokers,{array,[{node_id,int32},
                    {host,string},
                    {port,int32},
                    {rack,nullable_string}]}},
   {cluster_id,nullable_string},
   {controller_id,int32},
   {topics,{array,[{error_code,int16},
                   {name,string},
                   {is_internal,boolean},
                   {partitions,{array,[{error_code,int16},
                                       {partition_index,int32},
                                       {leader_id,int32},
                                       {replica_nodes,{array,int32}},
                                       {isr_nodes,{array,int32}},
                                       {offline_replicas,{array,int32}}]}}]}}];
rsp(metadata, 7) ->
  [{throttle_time_ms,int32},
   {brokers,{array,[{node_id,int32},
                    {host,string},
                    {port,int32},
                    {rack,nullable_string}]}},
   {cluster_id,nullable_string},
   {controller_id,int32},
   {topics,{array,[{error_code,int16},
                   {name,string},
                   {is_internal,boolean},
                   {partitions,{array,[{error_code,int16},
                                       {partition_index,int32},
                                       {leader_id,int32},
                                       {leader_epoch,int32},
                                       {replica_nodes,{array,int32}},
                                       {isr_nodes,{array,int32}},
                                       {offline_replicas,{array,int32}}]}}]}}];
rsp(metadata, 8) ->
  [{throttle_time_ms,int32},
   {brokers,{array,[{node_id,int32},
                    {host,string},
                    {port,int32},
                    {rack,nullable_string}]}},
   {cluster_id,nullable_string},
   {controller_id,int32},
   {topics,{array,[{error_code,int16},
                   {name,string},
                   {is_internal,boolean},
                   {partitions,{array,[{error_code,int16},
                                       {partition_index,int32},
                                       {leader_id,int32},
                                       {leader_epoch,int32},
                                       {replica_nodes,{array,int32}},
                                       {isr_nodes,{array,int32}},
                                       {offline_replicas,{array,int32}}]}},
                   {topic_authorized_operations,int32}]}},
   {cluster_authorized_operations,int32}];
rsp(metadata, 9) ->
  [{throttle_time_ms,int32},
   {brokers,
       {compact_array,
           [{node_id,int32},
            {host,compact_string},
            {port,int32},
            {rack,compact_nullable_string},
            {tagged_fields,tagged_fields}]}},
   {cluster_id,compact_nullable_string},
   {controller_id,int32},
   {topics,
       {compact_array,
           [{error_code,int16},
            {name,compact_string},
            {is_internal,boolean},
            {partitions,
                {compact_array,
                    [{error_code,int16},
                     {partition_index,int32},
                     {leader_id,int32},
                     {leader_epoch,int32},
                     {replica_nodes,{compact_array,int32}},
                     {isr_nodes,{compact_array,int32}},
                     {offline_replicas,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {topic_authorized_operations,int32},
            {tagged_fields,tagged_fields}]}},
   {cluster_authorized_operations,int32},
   {tagged_fields,tagged_fields}];
rsp(metadata, 10) ->
  [{throttle_time_ms,int32},
   {brokers,
       {compact_array,
           [{node_id,int32},
            {host,compact_string},
            {port,int32},
            {rack,compact_nullable_string},
            {tagged_fields,tagged_fields}]}},
   {cluster_id,compact_nullable_string},
   {controller_id,int32},
   {topics,
       {compact_array,
           [{error_code,int16},
            {name,compact_string},
            {topic_id,uuid},
            {is_internal,boolean},
            {partitions,
                {compact_array,
                    [{error_code,int16},
                     {partition_index,int32},
                     {leader_id,int32},
                     {leader_epoch,int32},
                     {replica_nodes,{compact_array,int32}},
                     {isr_nodes,{compact_array,int32}},
                     {offline_replicas,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {topic_authorized_operations,int32},
            {tagged_fields,tagged_fields}]}},
   {cluster_authorized_operations,int32},
   {tagged_fields,tagged_fields}];
rsp(metadata, 11) ->
  [{throttle_time_ms,int32},
   {brokers,
       {compact_array,
           [{node_id,int32},
            {host,compact_string},
            {port,int32},
            {rack,compact_nullable_string},
            {tagged_fields,tagged_fields}]}},
   {cluster_id,compact_nullable_string},
   {controller_id,int32},
   {topics,
       {compact_array,
           [{error_code,int16},
            {name,compact_string},
            {topic_id,uuid},
            {is_internal,boolean},
            {partitions,
                {compact_array,
                    [{error_code,int16},
                     {partition_index,int32},
                     {leader_id,int32},
                     {leader_epoch,int32},
                     {replica_nodes,{compact_array,int32}},
                     {isr_nodes,{compact_array,int32}},
                     {offline_replicas,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {topic_authorized_operations,int32},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(metadata, 12) ->
  [{throttle_time_ms,int32},
   {brokers,
       {compact_array,
           [{node_id,int32},
            {host,compact_string},
            {port,int32},
            {rack,compact_nullable_string},
            {tagged_fields,tagged_fields}]}},
   {cluster_id,compact_nullable_string},
   {controller_id,int32},
   {topics,
       {compact_array,
           [{error_code,int16},
            {name,compact_nullable_string},
            {topic_id,uuid},
            {is_internal,boolean},
            {partitions,
                {compact_array,
                    [{error_code,int16},
                     {partition_index,int32},
                     {leader_id,int32},
                     {leader_epoch,int32},
                     {replica_nodes,{compact_array,int32}},
                     {isr_nodes,{compact_array,int32}},
                     {offline_replicas,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {topic_authorized_operations,int32},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(metadata, 13) ->
  [{throttle_time_ms,int32},
   {brokers,
       {compact_array,
           [{node_id,int32},
            {host,compact_string},
            {port,int32},
            {rack,compact_nullable_string},
            {tagged_fields,tagged_fields}]}},
   {cluster_id,compact_nullable_string},
   {controller_id,int32},
   {topics,
       {compact_array,
           [{error_code,int16},
            {name,compact_nullable_string},
            {topic_id,uuid},
            {is_internal,boolean},
            {partitions,
                {compact_array,
                    [{error_code,int16},
                     {partition_index,int32},
                     {leader_id,int32},
                     {leader_epoch,int32},
                     {replica_nodes,{compact_array,int32}},
                     {isr_nodes,{compact_array,int32}},
                     {offline_replicas,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {topic_authorized_operations,int32},
            {tagged_fields,tagged_fields}]}},
   {error_code,int16},
   {tagged_fields,tagged_fields}];
rsp(offset_commit, 2) ->
  [{topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {error_code,int16}]}}]}}];
rsp(offset_commit, V) when V >= 3, V =< 7 ->
  [{throttle_time_ms,int32},
   {topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {error_code,int16}]}}]}}];
rsp(offset_commit, V) when V >= 8, V =< 9 ->
  [{throttle_time_ms,int32},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(offset_commit, 10) ->
  [{throttle_time_ms,int32},
   {topics,
       {compact_array,
           [{topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(offset_fetch, 1) ->
  [{topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {committed_offset,int64},
                                       {metadata,nullable_string},
                                       {error_code,int16}]}}]}}];
rsp(offset_fetch, 2) ->
  [{topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {committed_offset,int64},
                                       {metadata,nullable_string},
                                       {error_code,int16}]}}]}},
   {error_code,int16}];
rsp(offset_fetch, V) when V >= 3, V =< 4 ->
  [{throttle_time_ms,int32},
   {topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {committed_offset,int64},
                                       {metadata,nullable_string},
                                       {error_code,int16}]}}]}},
   {error_code,int16}];
rsp(offset_fetch, 5) ->
  [{throttle_time_ms,int32},
   {topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {committed_offset,int64},
                                       {committed_leader_epoch,int32},
                                       {metadata,nullable_string},
                                       {error_code,int16}]}}]}},
   {error_code,int16}];
rsp(offset_fetch, V) when V >= 6, V =< 7 ->
  [{throttle_time_ms,int32},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {committed_offset,int64},
                     {committed_leader_epoch,int32},
                     {metadata,compact_nullable_string},
                     {error_code,int16},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {error_code,int16},
   {tagged_fields,tagged_fields}];
rsp(offset_fetch, V) when V >= 8, V =< 9 ->
  [{throttle_time_ms,int32},
   {groups,
       {compact_array,
           [{group_id,compact_string},
            {topics,
                {compact_array,
                    [{name,compact_string},
                     {partitions,
                         {compact_array,
                             [{partition_index,int32},
                              {committed_offset,int64},
                              {committed_leader_epoch,int32},
                              {metadata,compact_nullable_string},
                              {error_code,int16},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {error_code,int16},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(offset_fetch, 10) ->
  [{throttle_time_ms,int32},
   {groups,
       {compact_array,
           [{group_id,compact_string},
            {topics,
                {compact_array,
                    [{topic_id,uuid},
                     {partitions,
                         {compact_array,
                             [{partition_index,int32},
                              {committed_offset,int64},
                              {committed_leader_epoch,int32},
                              {metadata,compact_nullable_string},
                              {error_code,int16},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {error_code,int16},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(find_coordinator, 0) ->
  [{error_code,int16},{node_id,int32},{host,string},{port,int32}];
rsp(find_coordinator, V) when V >= 1, V =< 2 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,nullable_string},
   {node_id,int32},
   {host,string},
   {port,int32}];
rsp(find_coordinator, 3) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {node_id,int32},
   {host,compact_string},
   {port,int32},
   {tagged_fields,tagged_fields}];
rsp(find_coordinator, V) when V >= 4, V =< 6 ->
  [{throttle_time_ms,int32},
   {coordinators,{compact_array,[{key,compact_string},
                                 {node_id,int32},
                                 {host,compact_string},
                                 {port,int32},
                                 {error_code,int16},
                                 {error_message,compact_nullable_string},
                                 {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(join_group, V) when V >= 0, V =< 1 ->
  [{error_code,int16},
   {generation_id,int32},
   {protocol_name,string},
   {leader,string},
   {member_id,string},
   {members,{array,[{member_id,string},{metadata,bytes}]}}];
rsp(join_group, V) when V >= 2, V =< 4 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {generation_id,int32},
   {protocol_name,string},
   {leader,string},
   {member_id,string},
   {members,{array,[{member_id,string},{metadata,bytes}]}}];
rsp(join_group, 5) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {generation_id,int32},
   {protocol_name,string},
   {leader,string},
   {member_id,string},
   {members,{array,[{member_id,string},
                    {group_instance_id,nullable_string},
                    {metadata,bytes}]}}];
rsp(join_group, 6) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {generation_id,int32},
   {protocol_name,compact_string},
   {leader,compact_string},
   {member_id,compact_string},
   {members,{compact_array,[{member_id,compact_string},
                            {group_instance_id,compact_nullable_string},
                            {metadata,compact_bytes},
                            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(join_group, V) when V >= 7, V =< 8 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {generation_id,int32},
   {protocol_type,compact_nullable_string},
   {protocol_name,compact_nullable_string},
   {leader,compact_string},
   {member_id,compact_string},
   {members,{compact_array,[{member_id,compact_string},
                            {group_instance_id,compact_nullable_string},
                            {metadata,compact_bytes},
                            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(join_group, 9) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {generation_id,int32},
   {protocol_type,compact_nullable_string},
   {protocol_name,compact_nullable_string},
   {leader,compact_string},
   {skip_assignment,boolean},
   {member_id,compact_string},
   {members,{compact_array,[{member_id,compact_string},
                            {group_instance_id,compact_nullable_string},
                            {metadata,compact_bytes},
                            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(heartbeat, 0) ->
  [{error_code,int16}];
rsp(heartbeat, V) when V >= 1, V =< 3 ->
  [{throttle_time_ms,int32},{error_code,int16}];
rsp(heartbeat, 4) ->
  [{throttle_time_ms,int32},{error_code,int16},{tagged_fields,tagged_fields}];
rsp(leave_group, 0) ->
  [{error_code,int16}];
rsp(leave_group, V) when V >= 1, V =< 2 ->
  [{throttle_time_ms,int32},{error_code,int16}];
rsp(leave_group, 3) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {members,{array,[{member_id,string},
                    {group_instance_id,nullable_string},
                    {error_code,int16}]}}];
rsp(leave_group, V) when V >= 4, V =< 5 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {members,{compact_array,[{member_id,compact_string},
                            {group_instance_id,compact_nullable_string},
                            {error_code,int16},
                            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(sync_group, 0) ->
  [{error_code,int16},{assignment,bytes}];
rsp(sync_group, V) when V >= 1, V =< 3 ->
  [{throttle_time_ms,int32},{error_code,int16},{assignment,bytes}];
rsp(sync_group, 4) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {assignment,compact_bytes},
   {tagged_fields,tagged_fields}];
rsp(sync_group, 5) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {protocol_type,compact_nullable_string},
   {protocol_name,compact_nullable_string},
   {assignment,compact_bytes},
   {tagged_fields,tagged_fields}];
rsp(describe_groups, 0) ->
  [{groups,{array,[{error_code,int16},
                   {group_id,string},
                   {group_state,string},
                   {protocol_type,string},
                   {protocol_data,string},
                   {members,{array,[{member_id,string},
                                    {client_id,string},
                                    {client_host,string},
                                    {member_metadata,bytes},
                                    {member_assignment,bytes}]}}]}}];
rsp(describe_groups, V) when V >= 1, V =< 2 ->
  [{throttle_time_ms,int32},
   {groups,{array,[{error_code,int16},
                   {group_id,string},
                   {group_state,string},
                   {protocol_type,string},
                   {protocol_data,string},
                   {members,{array,[{member_id,string},
                                    {client_id,string},
                                    {client_host,string},
                                    {member_metadata,bytes},
                                    {member_assignment,bytes}]}}]}}];
rsp(describe_groups, 3) ->
  [{throttle_time_ms,int32},
   {groups,{array,[{error_code,int16},
                   {group_id,string},
                   {group_state,string},
                   {protocol_type,string},
                   {protocol_data,string},
                   {members,{array,[{member_id,string},
                                    {client_id,string},
                                    {client_host,string},
                                    {member_metadata,bytes},
                                    {member_assignment,bytes}]}},
                   {authorized_operations,int32}]}}];
rsp(describe_groups, 4) ->
  [{throttle_time_ms,int32},
   {groups,{array,[{error_code,int16},
                   {group_id,string},
                   {group_state,string},
                   {protocol_type,string},
                   {protocol_data,string},
                   {members,{array,[{member_id,string},
                                    {group_instance_id,nullable_string},
                                    {client_id,string},
                                    {client_host,string},
                                    {member_metadata,bytes},
                                    {member_assignment,bytes}]}},
                   {authorized_operations,int32}]}}];
rsp(describe_groups, 5) ->
  [{throttle_time_ms,int32},
   {groups,
       {compact_array,
           [{error_code,int16},
            {group_id,compact_string},
            {group_state,compact_string},
            {protocol_type,compact_string},
            {protocol_data,compact_string},
            {members,
                {compact_array,
                    [{member_id,compact_string},
                     {group_instance_id,compact_nullable_string},
                     {client_id,compact_string},
                     {client_host,compact_string},
                     {member_metadata,compact_bytes},
                     {member_assignment,compact_bytes},
                     {tagged_fields,tagged_fields}]}},
            {authorized_operations,int32},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(describe_groups, 6) ->
  [{throttle_time_ms,int32},
   {groups,
       {compact_array,
           [{error_code,int16},
            {error_message,compact_nullable_string},
            {group_id,compact_string},
            {group_state,compact_string},
            {protocol_type,compact_string},
            {protocol_data,compact_string},
            {members,
                {compact_array,
                    [{member_id,compact_string},
                     {group_instance_id,compact_nullable_string},
                     {client_id,compact_string},
                     {client_host,compact_string},
                     {member_metadata,compact_bytes},
                     {member_assignment,compact_bytes},
                     {tagged_fields,tagged_fields}]}},
            {authorized_operations,int32},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(list_groups, 0) ->
  [{error_code,int16},
   {groups,{array,[{group_id,string},{protocol_type,string}]}}];
rsp(list_groups, V) when V >= 1, V =< 2 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {groups,{array,[{group_id,string},{protocol_type,string}]}}];
rsp(list_groups, 3) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {groups,{compact_array,[{group_id,compact_string},
                           {protocol_type,compact_string},
                           {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(list_groups, 4) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {groups,{compact_array,[{group_id,compact_string},
                           {protocol_type,compact_string},
                           {group_state,compact_string},
                           {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(list_groups, 5) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {groups,{compact_array,[{group_id,compact_string},
                           {protocol_type,compact_string},
                           {group_state,compact_string},
                           {group_type,compact_string},
                           {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(sasl_handshake, V) when V >= 0, V =< 1 ->
  [{error_code,int16},{mechanisms,{array,string}}];
rsp(api_versions, 0) ->
  [{error_code,int16},
   {api_keys,{array,[{api_key,int16},
                     {min_version,int16},
                     {max_version,int16}]}}];
rsp(api_versions, V) when V >= 1, V =< 2 ->
  [{error_code,int16},
   {api_keys,{array,[{api_key,int16},
                     {min_version,int16},
                     {max_version,int16}]}},
   {throttle_time_ms,int32}];
rsp(api_versions, V) when V >= 3, V =< 4 ->
  [{error_code,int16},
   {api_keys,{compact_array,[{api_key,int16},
                             {min_version,int16},
                             {max_version,int16},
                             {tagged_fields,tagged_fields}]}},
   {throttle_time_ms,int32},
   {tagged_fields,tagged_fields}];
rsp(create_topics, V) when V >= 2, V =< 4 ->
  [{throttle_time_ms,int32},
   {topics,{array,[{name,string},
                   {error_code,int16},
                   {error_message,nullable_string}]}}];
rsp(create_topics, V) when V >= 5, V =< 6 ->
  [{throttle_time_ms,int32},
   {topics,
       {compact_array,
           [{name,compact_string},
            {error_code,int16},
            {error_message,compact_nullable_string},
            {num_partitions,int32},
            {replication_factor,int16},
            {configs,
                {compact_array,
                    [{name,compact_string},
                     {value,compact_nullable_string},
                     {read_only,boolean},
                     {config_source,int8},
                     {is_sensitive,boolean},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(create_topics, 7) ->
  [{throttle_time_ms,int32},
   {topics,
       {compact_array,
           [{name,compact_string},
            {topic_id,uuid},
            {error_code,int16},
            {error_message,compact_nullable_string},
            {num_partitions,int32},
            {replication_factor,int16},
            {configs,
                {compact_array,
                    [{name,compact_string},
                     {value,compact_nullable_string},
                     {read_only,boolean},
                     {config_source,int8},
                     {is_sensitive,boolean},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(delete_topics, V) when V >= 1, V =< 3 ->
  [{throttle_time_ms,int32},
   {responses,{array,[{name,string},{error_code,int16}]}}];
rsp(delete_topics, 4) ->
  [{throttle_time_ms,int32},
   {responses,{compact_array,[{name,compact_string},
                              {error_code,int16},
                              {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(delete_topics, 5) ->
  [{throttle_time_ms,int32},
   {responses,{compact_array,[{name,compact_string},
                              {error_code,int16},
                              {error_message,compact_nullable_string},
                              {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(delete_topics, 6) ->
  [{throttle_time_ms,int32},
   {responses,{compact_array,[{name,compact_nullable_string},
                              {topic_id,uuid},
                              {error_code,int16},
                              {error_message,compact_nullable_string},
                              {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(delete_records, V) when V >= 0, V =< 1 ->
  [{throttle_time_ms,int32},
   {topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {low_watermark,int64},
                                       {error_code,int16}]}}]}}];
rsp(delete_records, 2) ->
  [{throttle_time_ms,int32},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {low_watermark,int64},
                     {error_code,int16},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(init_producer_id, V) when V >= 0, V =< 1 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {producer_id,int64},
   {producer_epoch,int16}];
rsp(init_producer_id, V) when V >= 2, V =< 5 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {producer_id,int64},
   {producer_epoch,int16},
   {tagged_fields,tagged_fields}];
rsp(init_producer_id, 6) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {producer_id,int64},
   {producer_epoch,int16},
   {ongoing_txn_producer_id,int64},
   {ongoing_txn_producer_epoch,int16},
   {tagged_fields,tagged_fields}];
rsp(offset_for_leader_epoch, V) when V >= 2, V =< 3 ->
  [{throttle_time_ms,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{error_code,int16},
                                       {partition,int32},
                                       {leader_epoch,int32},
                                       {end_offset,int64}]}}]}}];
rsp(offset_for_leader_epoch, 4) ->
  [{throttle_time_ms,int32},
   {topics,
       {compact_array,
           [{topic,compact_string},
            {partitions,
                {compact_array,
                    [{error_code,int16},
                     {partition,int32},
                     {leader_epoch,int32},
                     {end_offset,int64},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(add_partitions_to_txn, V) when V >= 0, V =< 2 ->
  [{throttle_time_ms,int32},
   {results,
       {array,
           [{name,string},
            {results_by_partition,
                {array,
                    [{partition_index,int32},
                     {partition_error_code,int16}]}}]}}];
rsp(add_partitions_to_txn, 3) ->
  [{throttle_time_ms,int32},
   {results,
       {compact_array,
           [{name,compact_string},
            {results_by_partition,
                {compact_array,
                    [{partition_index,int32},
                     {partition_error_code,int16},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(add_partitions_to_txn, V) when V >= 4, V =< 5 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {results_by_transaction,
       {compact_array,
           [{transactional_id,compact_string},
            {topic_results,
                {compact_array,
                    [{name,compact_string},
                     {results_by_partition,
                         {compact_array,
                             [{partition_index,int32},
                              {partition_error_code,int16},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(add_offsets_to_txn, V) when V >= 0, V =< 2 ->
  [{throttle_time_ms,int32},{error_code,int16}];
rsp(add_offsets_to_txn, V) when V >= 3, V =< 4 ->
  [{throttle_time_ms,int32},{error_code,int16},{tagged_fields,tagged_fields}];
rsp(end_txn, V) when V >= 0, V =< 2 ->
  [{throttle_time_ms,int32},{error_code,int16}];
rsp(end_txn, V) when V >= 3, V =< 4 ->
  [{throttle_time_ms,int32},{error_code,int16},{tagged_fields,tagged_fields}];
rsp(end_txn, 5) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {producer_id,int64},
   {producer_epoch,int16},
   {tagged_fields,tagged_fields}];
rsp(txn_offset_commit, V) when V >= 0, V =< 2 ->
  [{throttle_time_ms,int32},
   {topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {error_code,int16}]}}]}}];
rsp(txn_offset_commit, V) when V >= 3, V =< 5 ->
  [{throttle_time_ms,int32},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(describe_acls, 1) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,nullable_string},
   {resources,{array,[{resource_type,int8},
                      {resource_name,string},
                      {pattern_type,int8},
                      {acls,{array,[{principal,string},
                                    {host,string},
                                    {operation,int8},
                                    {permission_type,int8}]}}]}}];
rsp(describe_acls, V) when V >= 2, V =< 3 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {resources,
       {compact_array,
           [{resource_type,int8},
            {resource_name,compact_string},
            {pattern_type,int8},
            {acls,
                {compact_array,
                    [{principal,compact_string},
                     {host,compact_string},
                     {operation,int8},
                     {permission_type,int8},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(create_acls, 1) ->
  [{throttle_time_ms,int32},
   {results,{array,[{error_code,int16},{error_message,nullable_string}]}}];
rsp(create_acls, V) when V >= 2, V =< 3 ->
  [{throttle_time_ms,int32},
   {results,{compact_array,[{error_code,int16},
                            {error_message,compact_nullable_string},
                            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(delete_acls, 1) ->
  [{throttle_time_ms,int32},
   {filter_results,
       {array,
           [{error_code,int16},
            {error_message,nullable_string},
            {matching_acls,
                {array,
                    [{error_code,int16},
                     {error_message,nullable_string},
                     {resource_type,int8},
                     {resource_name,string},
                     {pattern_type,int8},
                     {principal,string},
                     {host,string},
                     {operation,int8},
                     {permission_type,int8}]}}]}}];
rsp(delete_acls, V) when V >= 2, V =< 3 ->
  [{throttle_time_ms,int32},
   {filter_results,
       {compact_array,
           [{error_code,int16},
            {error_message,compact_nullable_string},
            {matching_acls,
                {compact_array,
                    [{error_code,int16},
                     {error_message,compact_nullable_string},
                     {resource_type,int8},
                     {resource_name,compact_string},
                     {pattern_type,int8},
                     {principal,compact_string},
                     {host,compact_string},
                     {operation,int8},
                     {permission_type,int8},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(describe_configs, V) when V >= 1, V =< 2 ->
  [{throttle_time_ms,int32},
   {results,
       {array,
           [{error_code,int16},
            {error_message,nullable_string},
            {resource_type,int8},
            {resource_name,string},
            {configs,
                {array,
                    [{name,string},
                     {value,nullable_string},
                     {read_only,boolean},
                     {config_source,int8},
                     {is_sensitive,boolean},
                     {synonyms,
                         {array,
                             [{name,string},
                              {value,nullable_string},
                              {source,int8}]}}]}}]}}];
rsp(describe_configs, 3) ->
  [{throttle_time_ms,int32},
   {results,
       {array,
           [{error_code,int16},
            {error_message,nullable_string},
            {resource_type,int8},
            {resource_name,string},
            {configs,
                {array,
                    [{name,string},
                     {value,nullable_string},
                     {read_only,boolean},
                     {config_source,int8},
                     {is_sensitive,boolean},
                     {synonyms,
                         {array,
                             [{name,string},
                              {value,nullable_string},
                              {source,int8}]}},
                     {config_type,int8},
                     {documentation,nullable_string}]}}]}}];
rsp(describe_configs, 4) ->
  [{throttle_time_ms,int32},
   {results,
       {compact_array,
           [{error_code,int16},
            {error_message,compact_nullable_string},
            {resource_type,int8},
            {resource_name,compact_string},
            {configs,
                {compact_array,
                    [{name,compact_string},
                     {value,compact_nullable_string},
                     {read_only,boolean},
                     {config_source,int8},
                     {is_sensitive,boolean},
                     {synonyms,
                         {compact_array,
                             [{name,compact_string},
                              {value,compact_nullable_string},
                              {source,int8},
                              {tagged_fields,tagged_fields}]}},
                     {config_type,int8},
                     {documentation,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(alter_configs, V) when V >= 0, V =< 1 ->
  [{throttle_time_ms,int32},
   {responses,{array,[{error_code,int16},
                      {error_message,nullable_string},
                      {resource_type,int8},
                      {resource_name,string}]}}];
rsp(alter_configs, 2) ->
  [{throttle_time_ms,int32},
   {responses,{compact_array,[{error_code,int16},
                              {error_message,compact_nullable_string},
                              {resource_type,int8},
                              {resource_name,compact_string},
                              {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(alter_replica_log_dirs, 1) ->
  [{throttle_time_ms,int32},
   {results,
       {array,
           [{topic_name,string},
            {partitions,
                {array,[{partition_index,int32},{error_code,int16}]}}]}}];
rsp(alter_replica_log_dirs, 2) ->
  [{throttle_time_ms,int32},
   {results,
       {compact_array,
           [{topic_name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(describe_log_dirs, 1) ->
  [{throttle_time_ms,int32},
   {results,
       {array,
           [{error_code,int16},
            {log_dir,string},
            {topics,
                {array,
                    [{name,string},
                     {partitions,
                         {array,
                             [{partition_index,int32},
                              {partition_size,int64},
                              {offset_lag,int64},
                              {is_future_key,boolean}]}}]}}]}}];
rsp(describe_log_dirs, 2) ->
  [{throttle_time_ms,int32},
   {results,
       {compact_array,
           [{error_code,int16},
            {log_dir,compact_string},
            {topics,
                {compact_array,
                    [{name,compact_string},
                     {partitions,
                         {compact_array,
                             [{partition_index,int32},
                              {partition_size,int64},
                              {offset_lag,int64},
                              {is_future_key,boolean},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(describe_log_dirs, 3) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {results,
       {compact_array,
           [{error_code,int16},
            {log_dir,compact_string},
            {topics,
                {compact_array,
                    [{name,compact_string},
                     {partitions,
                         {compact_array,
                             [{partition_index,int32},
                              {partition_size,int64},
                              {offset_lag,int64},
                              {is_future_key,boolean},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(describe_log_dirs, 4) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {results,
       {compact_array,
           [{error_code,int16},
            {log_dir,compact_string},
            {topics,
                {compact_array,
                    [{name,compact_string},
                     {partitions,
                         {compact_array,
                             [{partition_index,int32},
                              {partition_size,int64},
                              {offset_lag,int64},
                              {is_future_key,boolean},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {total_bytes,int64},
            {usable_bytes,int64},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(sasl_authenticate, 0) ->
  [{error_code,int16},{error_message,nullable_string},{auth_bytes,bytes}];
rsp(sasl_authenticate, 1) ->
  [{error_code,int16},
   {error_message,nullable_string},
   {auth_bytes,bytes},
   {session_lifetime_ms,int64}];
rsp(sasl_authenticate, 2) ->
  [{error_code,int16},
   {error_message,compact_nullable_string},
   {auth_bytes,compact_bytes},
   {session_lifetime_ms,int64},
   {tagged_fields,tagged_fields}];
rsp(create_partitions, V) when V >= 0, V =< 1 ->
  [{throttle_time_ms,int32},
   {results,{array,[{name,string},
                    {error_code,int16},
                    {error_message,nullable_string}]}}];
rsp(create_partitions, V) when V >= 2, V =< 3 ->
  [{throttle_time_ms,int32},
   {results,{compact_array,[{name,compact_string},
                            {error_code,int16},
                            {error_message,compact_nullable_string},
                            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(create_delegation_token, 1) ->
  [{error_code,int16},
   {principal_type,string},
   {principal_name,string},
   {issue_timestamp_ms,int64},
   {expiry_timestamp_ms,int64},
   {max_timestamp_ms,int64},
   {token_id,string},
   {hmac,bytes},
   {throttle_time_ms,int32}];
rsp(create_delegation_token, 2) ->
  [{error_code,int16},
   {principal_type,compact_string},
   {principal_name,compact_string},
   {issue_timestamp_ms,int64},
   {expiry_timestamp_ms,int64},
   {max_timestamp_ms,int64},
   {token_id,compact_string},
   {hmac,compact_bytes},
   {throttle_time_ms,int32},
   {tagged_fields,tagged_fields}];
rsp(create_delegation_token, 3) ->
  [{error_code,int16},
   {principal_type,compact_string},
   {principal_name,compact_string},
   {token_requester_principal_type,compact_string},
   {token_requester_principal_name,compact_string},
   {issue_timestamp_ms,int64},
   {expiry_timestamp_ms,int64},
   {max_timestamp_ms,int64},
   {token_id,compact_string},
   {hmac,compact_bytes},
   {throttle_time_ms,int32},
   {tagged_fields,tagged_fields}];
rsp(renew_delegation_token, 1) ->
  [{error_code,int16},{expiry_timestamp_ms,int64},{throttle_time_ms,int32}];
rsp(renew_delegation_token, 2) ->
  [{error_code,int16},
   {expiry_timestamp_ms,int64},
   {throttle_time_ms,int32},
   {tagged_fields,tagged_fields}];
rsp(expire_delegation_token, 1) ->
  [{error_code,int16},{expiry_timestamp_ms,int64},{throttle_time_ms,int32}];
rsp(expire_delegation_token, 2) ->
  [{error_code,int16},
   {expiry_timestamp_ms,int64},
   {throttle_time_ms,int32},
   {tagged_fields,tagged_fields}];
rsp(describe_delegation_token, 1) ->
  [{error_code,int16},
   {tokens,{array,[{principal_type,string},
                   {principal_name,string},
                   {issue_timestamp,int64},
                   {expiry_timestamp,int64},
                   {max_timestamp,int64},
                   {token_id,string},
                   {hmac,bytes},
                   {renewers,{array,[{principal_type,string},
                                     {principal_name,string}]}}]}},
   {throttle_time_ms,int32}];
rsp(describe_delegation_token, 2) ->
  [{error_code,int16},
   {tokens,
       {compact_array,
           [{principal_type,compact_string},
            {principal_name,compact_string},
            {issue_timestamp,int64},
            {expiry_timestamp,int64},
            {max_timestamp,int64},
            {token_id,compact_string},
            {hmac,compact_bytes},
            {renewers,
                {compact_array,
                    [{principal_type,compact_string},
                     {principal_name,compact_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {throttle_time_ms,int32},
   {tagged_fields,tagged_fields}];
rsp(describe_delegation_token, 3) ->
  [{error_code,int16},
   {tokens,
       {compact_array,
           [{principal_type,compact_string},
            {principal_name,compact_string},
            {token_requester_principal_type,compact_string},
            {token_requester_principal_name,compact_string},
            {issue_timestamp,int64},
            {expiry_timestamp,int64},
            {max_timestamp,int64},
            {token_id,compact_string},
            {hmac,compact_bytes},
            {renewers,
                {compact_array,
                    [{principal_type,compact_string},
                     {principal_name,compact_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {throttle_time_ms,int32},
   {tagged_fields,tagged_fields}];
rsp(delete_groups, V) when V >= 0, V =< 1 ->
  [{throttle_time_ms,int32},
   {results,{array,[{group_id,string},{error_code,int16}]}}];
rsp(delete_groups, 2) ->
  [{throttle_time_ms,int32},
   {results,{compact_array,[{group_id,compact_string},
                            {error_code,int16},
                            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(elect_leaders, 0) ->
  [{throttle_time_ms,int32},
   {replica_election_results,
       {array,
           [{topic,string},
            {partition_result,
                {array,
                    [{partition_id,int32},
                     {error_code,int16},
                     {error_message,nullable_string}]}}]}}];
rsp(elect_leaders, 1) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {replica_election_results,
       {array,
           [{topic,string},
            {partition_result,
                {array,
                    [{partition_id,int32},
                     {error_code,int16},
                     {error_message,nullable_string}]}}]}}];
rsp(elect_leaders, 2) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {replica_election_results,
       {compact_array,
           [{topic,compact_string},
            {partition_result,
                {compact_array,
                    [{partition_id,int32},
                     {error_code,int16},
                     {error_message,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(incremental_alter_configs, 0) ->
  [{throttle_time_ms,int32},
   {responses,{array,[{error_code,int16},
                      {error_message,nullable_string},
                      {resource_type,int8},
                      {resource_name,string}]}}];
rsp(incremental_alter_configs, 1) ->
  [{throttle_time_ms,int32},
   {responses,{compact_array,[{error_code,int16},
                              {error_message,compact_nullable_string},
                              {resource_type,int8},
                              {resource_name,compact_string},
                              {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(alter_partition_reassignments, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {responses,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {error_message,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(alter_partition_reassignments, 1) ->
  [{throttle_time_ms,int32},
   {allow_replication_factor_change,boolean},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {responses,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {error_message,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(list_partition_reassignments, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {replicas,{compact_array,int32}},
                     {adding_replicas,{compact_array,int32}},
                     {removing_replicas,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(offset_delete, 0) ->
  [{error_code,int16},
   {throttle_time_ms,int32},
   {topics,{array,[{name,string},
                   {partitions,{array,[{partition_index,int32},
                                       {error_code,int16}]}}]}}];
rsp(describe_client_quotas, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,nullable_string},
   {entries,{array,[{entity,{array,[{entity_type,string},
                                    {entity_name,nullable_string}]}},
                    {values,{array,[{key,string},{value,float64}]}}]}}];
rsp(describe_client_quotas, 1) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {entries,
       {compact_array,
           [{entity,
                {compact_array,
                    [{entity_type,compact_string},
                     {entity_name,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {values,
                {compact_array,
                    [{key,compact_string},
                     {value,float64},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(alter_client_quotas, 0) ->
  [{throttle_time_ms,int32},
   {entries,{array,[{error_code,int16},
                    {error_message,nullable_string},
                    {entity,{array,[{entity_type,string},
                                    {entity_name,nullable_string}]}}]}}];
rsp(alter_client_quotas, 1) ->
  [{throttle_time_ms,int32},
   {entries,
       {compact_array,
           [{error_code,int16},
            {error_message,compact_nullable_string},
            {entity,
                {compact_array,
                    [{entity_type,compact_string},
                     {entity_name,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(describe_user_scram_credentials, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {results,
       {compact_array,
           [{user,compact_string},
            {error_code,int16},
            {error_message,compact_nullable_string},
            {credential_infos,
                {compact_array,
                    [{mechanism,int8},
                     {iterations,int32},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(alter_user_scram_credentials, 0) ->
  [{throttle_time_ms,int32},
   {results,{compact_array,[{user,compact_string},
                            {error_code,int16},
                            {error_message,compact_nullable_string},
                            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(fetch_snapshot, V) when V >= 0, V =< 1 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{index,int32},
                     {error_code,int16},
                     {snapshot_id,
                         [{end_offset,int64},
                          {epoch,int32},
                          {tagged_fields,tagged_fields}]},
                     {size,int64},
                     {position,int64},
                     {unaligned_records,compact_records},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(describe_cluster, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {cluster_id,compact_string},
   {controller_id,int32},
   {brokers,{compact_array,[{broker_id,int32},
                            {host,compact_string},
                            {port,int32},
                            {rack,compact_nullable_string},
                            {tagged_fields,tagged_fields}]}},
   {cluster_authorized_operations,int32},
   {tagged_fields,tagged_fields}];
rsp(describe_cluster, 1) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {endpoint_type,int8},
   {cluster_id,compact_string},
   {controller_id,int32},
   {brokers,{compact_array,[{broker_id,int32},
                            {host,compact_string},
                            {port,int32},
                            {rack,compact_nullable_string},
                            {tagged_fields,tagged_fields}]}},
   {cluster_authorized_operations,int32},
   {tagged_fields,tagged_fields}];
rsp(describe_cluster, 2) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {endpoint_type,int8},
   {cluster_id,compact_string},
   {controller_id,int32},
   {brokers,{compact_array,[{broker_id,int32},
                            {host,compact_string},
                            {port,int32},
                            {rack,compact_nullable_string},
                            {is_fenced,boolean},
                            {tagged_fields,tagged_fields}]}},
   {cluster_authorized_operations,int32},
   {tagged_fields,tagged_fields}];
rsp(describe_producers, 0) ->
  [{throttle_time_ms,int32},
   {topics,
       {compact_array,
           [{name,compact_string},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {error_message,compact_nullable_string},
                     {active_producers,
                         {compact_array,
                             [{producer_id,int64},
                              {producer_epoch,int32},
                              {last_sequence,int32},
                              {last_timestamp,int64},
                              {coordinator_epoch,int32},
                              {current_txn_start_offset,int64},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(unregister_broker, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {tagged_fields,tagged_fields}];
rsp(describe_transactions, 0) ->
  [{throttle_time_ms,int32},
   {transaction_states,
       {compact_array,
           [{error_code,int16},
            {transactional_id,compact_string},
            {transaction_state,compact_string},
            {transaction_timeout_ms,int32},
            {transaction_start_time_ms,int64},
            {producer_id,int64},
            {producer_epoch,int16},
            {topics,
                {compact_array,
                    [{topic,compact_string},
                     {partitions,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(list_transactions, V) when V >= 0, V =< 2 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {unknown_state_filters,{compact_array,compact_string}},
   {transaction_states,{compact_array,[{transactional_id,compact_string},
                                       {producer_id,int64},
                                       {transaction_state,compact_string},
                                       {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(consumer_group_heartbeat, V) when V >= 0, V =< 1 ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {member_id,compact_nullable_string},
   {member_epoch,int32},
   {heartbeat_interval_ms,int32},
   {assignment,
       [{topic_partitions,
            {compact_array,
                [{topic_id,uuid},
                 {partitions,{compact_array,int32}},
                 {tagged_fields,tagged_fields}]}},
        {tagged_fields,tagged_fields}]},
   {tagged_fields,tagged_fields}];
rsp(consumer_group_describe, 0) ->
  [{throttle_time_ms,int32},
   {groups,
       {compact_array,
           [{error_code,int16},
            {error_message,compact_nullable_string},
            {group_id,compact_string},
            {group_state,compact_string},
            {group_epoch,int32},
            {assignment_epoch,int32},
            {assignor_name,compact_string},
            {members,
                {compact_array,
                    [{member_id,compact_string},
                     {instance_id,compact_nullable_string},
                     {rack_id,compact_nullable_string},
                     {member_epoch,int32},
                     {client_id,compact_string},
                     {client_host,compact_string},
                     {subscribed_topic_names,{compact_array,compact_string}},
                     {subscribed_topic_regex,compact_nullable_string},
                     {assignment,
                         [{topic_partitions,
                              {compact_array,
                                  [{topic_id,uuid},
                                   {topic_name,compact_string},
                                   {partitions,{compact_array,int32}},
                                   {tagged_fields,tagged_fields}]}},
                          {tagged_fields,tagged_fields}]},
                     {target_assignment,
                         [{topic_partitions,
                              {compact_array,
                                  [{topic_id,uuid},
                                   {topic_name,compact_string},
                                   {partitions,{compact_array,int32}},
                                   {tagged_fields,tagged_fields}]}},
                          {tagged_fields,tagged_fields}]},
                     {tagged_fields,tagged_fields}]}},
            {authorized_operations,int32},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(consumer_group_describe, 1) ->
  [{throttle_time_ms,int32},
   {groups,
       {compact_array,
           [{error_code,int16},
            {error_message,compact_nullable_string},
            {group_id,compact_string},
            {group_state,compact_string},
            {group_epoch,int32},
            {assignment_epoch,int32},
            {assignor_name,compact_string},
            {members,
                {compact_array,
                    [{member_id,compact_string},
                     {instance_id,compact_nullable_string},
                     {rack_id,compact_nullable_string},
                     {member_epoch,int32},
                     {client_id,compact_string},
                     {client_host,compact_string},
                     {subscribed_topic_names,{compact_array,compact_string}},
                     {subscribed_topic_regex,compact_nullable_string},
                     {assignment,
                         [{topic_partitions,
                              {compact_array,
                                  [{topic_id,uuid},
                                   {topic_name,compact_string},
                                   {partitions,{compact_array,int32}},
                                   {tagged_fields,tagged_fields}]}},
                          {tagged_fields,tagged_fields}]},
                     {target_assignment,
                         [{topic_partitions,
                              {compact_array,
                                  [{topic_id,uuid},
                                   {topic_name,compact_string},
                                   {partitions,{compact_array,int32}},
                                   {tagged_fields,tagged_fields}]}},
                          {tagged_fields,tagged_fields}]},
                     {member_type,int8},
                     {tagged_fields,tagged_fields}]}},
            {authorized_operations,int32},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(controller_registration, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {tagged_fields,tagged_fields}];
rsp(get_telemetry_subscriptions, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {client_instance_id,uuid},
   {subscription_id,int32},
   {accepted_compression_types,{compact_array,int8}},
   {push_interval_ms,int32},
   {telemetry_max_bytes,int32},
   {delta_temporality,boolean},
   {requested_metrics,{compact_array,compact_string}},
   {tagged_fields,tagged_fields}];
rsp(push_telemetry, 0) ->
  [{throttle_time_ms,int32},{error_code,int16},{tagged_fields,tagged_fields}];
rsp(assign_replicas_to_dirs, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {directories,
       {compact_array,
           [{id,uuid},
            {topics,
                {compact_array,
                    [{topic_id,uuid},
                     {partitions,
                         {compact_array,
                             [{partition_index,int32},
                              {error_code,int16},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(list_config_resources, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {config_resources,{compact_array,[{resource_name,compact_string},
                                     {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(list_config_resources, 1) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {config_resources,{compact_array,[{resource_name,compact_string},
                                     {resource_type,int8},
                                     {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(describe_topic_partitions, 0) ->
  [{throttle_time_ms,int32},
   {topics,
       {compact_array,
           [{error_code,int16},
            {name,compact_nullable_string},
            {topic_id,uuid},
            {is_internal,boolean},
            {partitions,
                {compact_array,
                    [{error_code,int16},
                     {partition_index,int32},
                     {leader_id,int32},
                     {leader_epoch,int32},
                     {replica_nodes,{compact_array,int32}},
                     {isr_nodes,{compact_array,int32}},
                     {eligible_leader_replicas,{compact_array,int32}},
                     {last_known_elr,{compact_array,int32}},
                     {offline_replicas,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {topic_authorized_operations,int32},
            {tagged_fields,tagged_fields}]}},
   {next_cursor,
       [{topic_name,compact_string},
        {partition_index,int32},
        {tagged_fields,tagged_fields}]},
   {tagged_fields,tagged_fields}];
rsp(share_group_heartbeat, 1) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {member_id,compact_nullable_string},
   {member_epoch,int32},
   {heartbeat_interval_ms,int32},
   {assignment,
       [{topic_partitions,
            {compact_array,
                [{topic_id,uuid},
                 {partitions,{compact_array,int32}},
                 {tagged_fields,tagged_fields}]}},
        {tagged_fields,tagged_fields}]},
   {tagged_fields,tagged_fields}];
rsp(share_group_describe, 1) ->
  [{throttle_time_ms,int32},
   {groups,
       {compact_array,
           [{error_code,int16},
            {error_message,compact_nullable_string},
            {group_id,compact_string},
            {group_state,compact_string},
            {group_epoch,int32},
            {assignment_epoch,int32},
            {assignor_name,compact_string},
            {members,
                {compact_array,
                    [{member_id,compact_string},
                     {rack_id,compact_nullable_string},
                     {member_epoch,int32},
                     {client_id,compact_string},
                     {client_host,compact_string},
                     {subscribed_topic_names,{compact_array,compact_string}},
                     {assignment,
                         [{topic_partitions,
                              {compact_array,
                                  [{topic_id,uuid},
                                   {topic_name,compact_string},
                                   {partitions,{compact_array,int32}},
                                   {tagged_fields,tagged_fields}]}},
                          {tagged_fields,tagged_fields}]},
                     {tagged_fields,tagged_fields}]}},
            {authorized_operations,int32},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(share_fetch, 1) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {acquisition_lock_timeout_ms,int32},
   {responses,
       {compact_array,
           [{topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {error_message,compact_nullable_string},
                     {acknowledge_error_code,int16},
                     {acknowledge_error_message,compact_nullable_string},
                     {current_leader,
                         [{leader_id,int32},
                          {leader_epoch,int32},
                          {tagged_fields,tagged_fields}]},
                     {records,compact_records},
                     {acquired_records,
                         {compact_array,
                             [{first_offset,int64},
                              {last_offset,int64},
                              {delivery_count,int16},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {node_endpoints,
       {compact_array,
           [{node_id,int32},
            {host,compact_string},
            {port,int32},
            {rack,compact_nullable_string},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(share_acknowledge, 1) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {responses,
       {compact_array,
           [{topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {error_message,compact_nullable_string},
                     {current_leader,
                         [{leader_id,int32},
                          {leader_epoch,int32},
                          {tagged_fields,tagged_fields}]},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {node_endpoints,
       {compact_array,
           [{node_id,int32},
            {host,compact_string},
            {port,int32},
            {rack,compact_nullable_string},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(add_raft_voter, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {tagged_fields,tagged_fields}];
rsp(remove_raft_voter, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {tagged_fields,tagged_fields}];
rsp(update_raft_voter, 0) ->
  [{throttle_time_ms,int32},{error_code,int16},{tagged_fields,tagged_fields}];
rsp(streams_group_heartbeat, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {member_id,compact_string},
   {member_epoch,int32},
   {heartbeat_interval_ms,int32},
   {acceptable_recovery_lag,int32},
   {task_offset_interval_ms,int32},
   {status,
       {compact_array,
           [{status_code,int8},
            {status_detail,compact_string},
            {tagged_fields,tagged_fields}]}},
   {active_tasks,
       {compact_array,
           [{subtopology_id,compact_string},
            {partitions,{compact_array,int32}},
            {tagged_fields,tagged_fields}]}},
   {standby_tasks,
       {compact_array,
           [{subtopology_id,compact_string},
            {partitions,{compact_array,int32}},
            {tagged_fields,tagged_fields}]}},
   {warmup_tasks,
       {compact_array,
           [{subtopology_id,compact_string},
            {partitions,{compact_array,int32}},
            {tagged_fields,tagged_fields}]}},
   {endpoint_information_epoch,int32},
   {partitions_by_user_endpoint,
       {compact_array,
           [{user_endpoint,
                [{host,compact_string},
                 {port,uint16},
                 {tagged_fields,tagged_fields}]},
            {active_partitions,
                {compact_array,
                    [{topic,compact_string},
                     {partitions,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {standby_partitions,
                {compact_array,
                    [{topic,compact_string},
                     {partitions,{compact_array,int32}},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(streams_group_describe, 0) ->
  [{throttle_time_ms,int32},
   {groups,
    {compact_array,
     [{error_code,int16},
      {error_message,compact_nullable_string},
      {group_id,compact_string},
      {group_state,compact_string},
      {group_epoch,int32},
      {assignment_epoch,int32},
      {topology,
       [{epoch,int32},
        {subtopologies,
         {compact_array,
          [{subtopology_id,compact_string},
           {source_topics,{compact_array,compact_string}},
           {repartition_sink_topics,{compact_array,compact_string}},
           {state_changelog_topics,
            {compact_array,
             [{name,compact_string},
              {partitions,int32},
              {replication_factor,int16},
              {topic_configs,
               {compact_array,
                [{key,compact_string},
                 {value,compact_string},
                 {tagged_fields,tagged_fields}]}},
              {tagged_fields,tagged_fields}]}},
           {repartition_source_topics,
            {compact_array,
             [{name,compact_string},
              {partitions,int32},
              {replication_factor,int16},
              {topic_configs,
               {compact_array,
                [{key,compact_string},
                 {value,compact_string},
                 {tagged_fields,tagged_fields}]}},
              {tagged_fields,tagged_fields}]}},
           {tagged_fields,tagged_fields}]}},
        {tagged_fields,tagged_fields}]},
      {members,
       {compact_array,
        [{member_id,compact_string},
         {member_epoch,int32},
         {instance_id,compact_nullable_string},
         {rack_id,compact_nullable_string},
         {client_id,compact_string},
         {client_host,compact_string},
         {topology_epoch,int32},
         {process_id,compact_string},
         {user_endpoint,
          [{host,compact_string},{port,uint16},{tagged_fields,tagged_fields}]},
         {client_tags,
          {compact_array,
           [{key,compact_string},
            {value,compact_string},
            {tagged_fields,tagged_fields}]}},
         {task_offsets,
          {compact_array,
           [{subtopology_id,compact_string},
            {partition,int32},
            {offset,int64},
            {tagged_fields,tagged_fields}]}},
         {task_end_offsets,
          {compact_array,
           [{subtopology_id,compact_string},
            {partition,int32},
            {offset,int64},
            {tagged_fields,tagged_fields}]}},
         {assignment,
          [{active_tasks,
            {compact_array,
             [{subtopology_id,compact_string},
              {partitions,{compact_array,int32}},
              {tagged_fields,tagged_fields}]}},
           {standby_tasks,
            {compact_array,
             [{subtopology_id,compact_string},
              {partitions,{compact_array,int32}},
              {tagged_fields,tagged_fields}]}},
           {warmup_tasks,
            {compact_array,
             [{subtopology_id,compact_string},
              {partitions,{compact_array,int32}},
              {tagged_fields,tagged_fields}]}},
           {tagged_fields,tagged_fields}]},
         {target_assignment,
          [{active_tasks,
            {compact_array,
             [{subtopology_id,compact_string},
              {partitions,{compact_array,int32}},
              {tagged_fields,tagged_fields}]}},
           {standby_tasks,
            {compact_array,
             [{subtopology_id,compact_string},
              {partitions,{compact_array,int32}},
              {tagged_fields,tagged_fields}]}},
           {warmup_tasks,
            {compact_array,
             [{subtopology_id,compact_string},
              {partitions,{compact_array,int32}},
              {tagged_fields,tagged_fields}]}},
           {tagged_fields,tagged_fields}]},
         {is_classic,boolean},
         {tagged_fields,tagged_fields}]}},
      {authorized_operations,int32},
      {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(describe_share_group_offsets, 0) ->
  [{throttle_time_ms,int32},
   {groups,
       {compact_array,
           [{group_id,compact_string},
            {topics,
                {compact_array,
                    [{topic_name,compact_string},
                     {topic_id,uuid},
                     {partitions,
                         {compact_array,
                             [{partition_index,int32},
                              {start_offset,int64},
                              {leader_epoch,int32},
                              {error_code,int16},
                              {error_message,compact_nullable_string},
                              {tagged_fields,tagged_fields}]}},
                     {tagged_fields,tagged_fields}]}},
            {error_code,int16},
            {error_message,compact_nullable_string},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(alter_share_group_offsets, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {responses,
       {compact_array,
           [{topic_name,compact_string},
            {topic_id,uuid},
            {partitions,
                {compact_array,
                    [{partition_index,int32},
                     {error_code,int16},
                     {error_message,compact_nullable_string},
                     {tagged_fields,tagged_fields}]}},
            {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}];
rsp(delete_share_group_offsets, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,compact_nullable_string},
   {responses,{compact_array,[{topic_name,compact_string},
                              {topic_id,uuid},
                              {error_code,int16},
                              {error_message,compact_nullable_string},
                              {tagged_fields,tagged_fields}]}},
   {tagged_fields,tagged_fields}].
ec(0) -> no_error;
ec(-1) -> unknown_server_error;
ec(1) -> offset_out_of_range;
ec(2) -> corrupt_message;
ec(3) -> unknown_topic_or_partition;
ec(4) -> invalid_fetch_size;
ec(5) -> leader_not_available;
ec(6) -> not_leader_for_partition;
ec(7) -> request_timed_out;
ec(8) -> broker_not_available;
ec(9) -> replica_not_available;
ec(10) -> message_too_large;
ec(11) -> stale_controller_epoch;
ec(12) -> offset_metadata_too_large;
ec(13) -> network_exception;
ec(14) -> coordinator_load_in_progress;
ec(15) -> coordinator_not_available;
ec(16) -> not_coordinator;
ec(17) -> invalid_topic_exception;
ec(18) -> record_list_too_large;
ec(19) -> not_enough_replicas;
ec(20) -> not_enough_replicas_after_append;
ec(21) -> invalid_required_acks;
ec(22) -> illegal_generation;
ec(23) -> inconsistent_group_protocol;
ec(24) -> invalid_group_id;
ec(25) -> unknown_member_id;
ec(26) -> invalid_session_timeout;
ec(27) -> rebalance_in_progress;
ec(28) -> invalid_commit_offset_size;
ec(29) -> topic_authorization_failed;
ec(30) -> group_authorization_failed;
ec(31) -> cluster_authorization_failed;
ec(32) -> invalid_timestamp;
ec(33) -> unsupported_sasl_mechanism;
ec(34) -> illegal_sasl_state;
ec(35) -> unsupported_version;
ec(36) -> topic_already_exists;
ec(37) -> invalid_partitions;
ec(38) -> invalid_replication_factor;
ec(39) -> invalid_replica_assignment;
ec(40) -> invalid_config;
ec(41) -> not_controller;
ec(42) -> invalid_request;
ec(43) -> unsupported_for_message_format;
ec(44) -> policy_violation;
ec(45) -> out_of_order_sequence_number;
ec(46) -> duplicate_sequence_number;
ec(47) -> invalid_producer_epoch;
ec(48) -> invalid_txn_state;
ec(49) -> invalid_producer_id_mapping;
ec(50) -> invalid_transaction_timeout;
ec(51) -> concurrent_transactions;
ec(52) -> transaction_coordinator_fenced;
ec(53) -> transactional_id_authorization_failed;
ec(54) -> security_disabled;
ec(55) -> operation_not_attempted;
ec(56) -> kafka_storage_error;
ec(57) -> log_dir_not_found;
ec(58) -> sasl_authentication_failed;
ec(59) -> unknown_producer_id;
ec(60) -> reassignment_in_progress;
ec(61) -> delegation_token_auth_disabled;
ec(62) -> delegation_token_not_found;
ec(63) -> delegation_token_owner_mismatch;
ec(64) -> delegation_token_request_not_allowed;
ec(65) -> delegation_token_authorization_failed;
ec(66) -> delegation_token_expired;
ec(67) -> invalid_principal_type;
ec(68) -> non_empty_group;
ec(69) -> group_id_not_found;
ec(70) -> fetch_session_id_not_found;
ec(71) -> invalid_fetch_session_epoch;
ec(72) -> listener_not_found;
ec(73) -> topic_deletion_disabled;
ec(74) -> fenced_leader_epoch;
ec(75) -> unknown_leader_epoch;
ec(76) -> unsupported_compression_type;
ec(77) -> stale_broker_epoch;
ec(78) -> offset_not_available;
ec(79) -> member_id_required;
ec(80) -> preferred_leader_not_available;
ec(81) -> group_max_size_reached;
ec(82) -> fenced_instance_id;
ec(83) -> eligible_leaders_not_available;
ec(84) -> election_not_needed;
ec(85) -> no_reassignment_in_progress;
ec(86) -> group_subscribed_to_topic;
ec(87) -> invalid_record;
ec(88) -> unstable_offset_commit;
ec(ErrorCode) -> ErrorCode.
