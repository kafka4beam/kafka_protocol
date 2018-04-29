%% generated code, do not edit!
-module(kpro_schema).
-export([all_apis/0, vsn_range/1, api_key/1, req/2, rsp/2, ec/1]).

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
delete_groups].

vsn_range(produce) -> {0, 5};
vsn_range(fetch) -> {0, 7};
vsn_range(list_offsets) -> {0, 2};
vsn_range(metadata) -> {0, 5};
vsn_range(offset_commit) -> {0, 3};
vsn_range(offset_fetch) -> {0, 3};
vsn_range(find_coordinator) -> {0, 1};
vsn_range(join_group) -> {0, 2};
vsn_range(heartbeat) -> {0, 1};
vsn_range(leave_group) -> {0, 1};
vsn_range(sync_group) -> {0, 1};
vsn_range(describe_groups) -> {0, 1};
vsn_range(list_groups) -> {0, 1};
vsn_range(sasl_handshake) -> {0, 1};
vsn_range(api_versions) -> {0, 1};
vsn_range(create_topics) -> {0, 2};
vsn_range(delete_topics) -> {0, 1};
vsn_range(delete_records) -> {0, 0};
vsn_range(init_producer_id) -> {0, 0};
vsn_range(add_partitions_to_txn) -> {0, 0};
vsn_range(add_offsets_to_txn) -> {0, 0};
vsn_range(end_txn) -> {0, 0};
vsn_range(txn_offset_commit) -> {0, 0};
vsn_range(describe_acls) -> {0, 0};
vsn_range(create_acls) -> {0, 0};
vsn_range(delete_acls) -> {0, 0};
vsn_range(describe_configs) -> {0, 1};
vsn_range(alter_configs) -> {0, 0};
vsn_range(alter_replica_log_dirs) -> {0, 0};
vsn_range(describe_log_dirs) -> {0, 0};
vsn_range(sasl_authenticate) -> {0, 0};
vsn_range(create_partitions) -> {0, 0};
vsn_range(create_delegation_token) -> {0, 0};
vsn_range(renew_delegation_token) -> {0, 0};
vsn_range(expire_delegation_token) -> {0, 0};
vsn_range(describe_delegation_token) -> {0, 0};
vsn_range(delete_groups) -> {0, 0};
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
api_key(API) -> erlang:error({not_supported, API}).

req(produce, V) when V >= 0, V =< 2 ->
  [{acks,int16},
   {timeout,int32},
   {topic_data,{array,[{topic,string},
                       {data,{array,[{partition,int32},
                                     {record_set,records}]}}]}}];
req(produce, V) when V >= 3, V =< 5 ->
  [{transactional_id,nullable_string},
   {acks,int16},
   {timeout,int32},
   {topic_data,{array,[{topic,string},
                       {data,{array,[{partition,int32},
                                     {record_set,records}]}}]}}];
req(fetch, V) when V >= 0, V =< 2 ->
  [{replica_id,int32},
   {max_wait_time,int32},
   {min_bytes,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {fetch_offset,int64},
                                       {max_bytes,int32}]}}]}}];
req(fetch, 3) ->
  [{replica_id,int32},
   {max_wait_time,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {fetch_offset,int64},
                                       {max_bytes,int32}]}}]}}];
req(fetch, 4) ->
  [{replica_id,int32},
   {max_wait_time,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {isolation_level,int8},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {fetch_offset,int64},
                                       {max_bytes,int32}]}}]}}];
req(fetch, V) when V >= 5, V =< 6 ->
  [{replica_id,int32},
   {max_wait_time,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {isolation_level,int8},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {fetch_offset,int64},
                                       {log_start_offset,int64},
                                       {max_bytes,int32}]}}]}}];
req(fetch, 7) ->
  [{replica_id,int32},
   {max_wait_time,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {isolation_level,int8},
   {session_id,int32},
   {epoch,int32},
   {topics,
       {array,
           [{topic,string},
            {partitions,
                {array,
                    [{partition,int32},
                     {fetch_offset,int64},
                     {log_start_offset,int64},
                     {max_bytes,int32}]}}]}},
   {forgetten_topics_data,
       {array,
           [{topic,string},
            {partitions,
                {array,
                    [{partition,int32},
                     {fetch_offset,int64},
                     {log_start_offset,int64},
                     {max_bytes,int32}]}}]}}];
req(list_offsets, 0) ->
  [{replica_id,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {timestamp,int64},
                                       {max_num_offsets,int32}]}}]}}];
req(list_offsets, 1) ->
  [{replica_id,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {timestamp,int64}]}}]}}];
req(list_offsets, 2) ->
  [{replica_id,int32},
   {isolation_level,int8},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {timestamp,int64}]}}]}}];
req(metadata, V) when V >= 0, V =< 3 ->
  [{topics,{array,string}}];
req(metadata, V) when V >= 4, V =< 5 ->
  [{topics,{array,string}},{allow_auto_topic_creation,boolean}];
req(offset_commit, 0) ->
  [{group_id,string},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {offset,int64},
                                       {metadata,nullable_string}]}}]}}];
req(offset_commit, 1) ->
  [{group_id,string},
   {generation_id,int32},
   {member_id,string},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {offset,int64},
                                       {timestamp,int64},
                                       {metadata,nullable_string}]}}]}}];
req(offset_commit, V) when V >= 2, V =< 3 ->
  [{group_id,string},
   {generation_id,int32},
   {member_id,string},
   {retention_time,int64},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {offset,int64},
                                       {metadata,nullable_string}]}}]}}];
req(offset_fetch, V) when V >= 0, V =< 3 ->
  [{group_id,string},
   {topics,{array,[{topic,string},{partitions,{array,[{partition,int32}]}}]}}];
req(find_coordinator, 0) ->
  [{group_id,string}];
req(find_coordinator, 1) ->
  [{coordinator_key,string},{coordinator_type,int8}];
req(join_group, 0) ->
  [{group_id,string},
   {session_timeout,int32},
   {member_id,string},
   {protocol_type,string},
   {group_protocols,{array,[{protocol_name,string},
                            {protocol_metadata,bytes}]}}];
req(join_group, V) when V >= 1, V =< 2 ->
  [{group_id,string},
   {session_timeout,int32},
   {rebalance_timeout,int32},
   {member_id,string},
   {protocol_type,string},
   {group_protocols,{array,[{protocol_name,string},
                            {protocol_metadata,bytes}]}}];
req(heartbeat, V) when V >= 0, V =< 1 ->
  [{group_id,string},{generation_id,int32},{member_id,string}];
req(leave_group, V) when V >= 0, V =< 1 ->
  [{group_id,string},{member_id,string}];
req(sync_group, V) when V >= 0, V =< 1 ->
  [{group_id,string},
   {generation_id,int32},
   {member_id,string},
   {group_assignment,{array,[{member_id,string},{member_assignment,bytes}]}}];
req(describe_groups, V) when V >= 0, V =< 1 ->
  [{group_ids,{array,string}}];
req(list_groups, V) when V >= 0, V =< 1 ->
  [];
req(sasl_handshake, V) when V >= 0, V =< 1 ->
  [{mechanism,string}];
req(api_versions, V) when V >= 0, V =< 1 ->
  [];
req(create_topics, 0) ->
  [{create_topic_requests,
       {array,
           [{topic,string},
            {num_partitions,int32},
            {replication_factor,int16},
            {replica_assignment,
                {array,[{partition,int32},{replicas,{array,int32}}]}},
            {config_entries,
                {array,
                    [{config_name,string},{config_value,nullable_string}]}}]}},
   {timeout,int32}];
req(create_topics, V) when V >= 1, V =< 2 ->
  [{create_topic_requests,
       {array,
           [{topic,string},
            {num_partitions,int32},
            {replication_factor,int16},
            {replica_assignment,
                {array,[{partition,int32},{replicas,{array,int32}}]}},
            {config_entries,
                {array,
                    [{config_name,string},{config_value,nullable_string}]}}]}},
   {timeout,int32},
   {validate_only,boolean}];
req(delete_topics, V) when V >= 0, V =< 1 ->
  [{topics,{array,string}},{timeout,int32}];
req(delete_records, 0) ->
  [{topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},{offset,int64}]}}]}},
   {timeout,int32}];
req(init_producer_id, 0) ->
  [{transactional_id,nullable_string},{transaction_timeout_ms,int32}];
req(add_partitions_to_txn, 0) ->
  [{transactional_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {topics,{array,[{topic,string},{partitions,{array,int32}}]}}];
req(add_offsets_to_txn, 0) ->
  [{transactional_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {group_id,string}];
req(end_txn, 0) ->
  [{transactional_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {transaction_result,boolean}];
req(txn_offset_commit, 0) ->
  [{transactional_id,string},
   {group_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {offset,int64},
                                       {metadata,nullable_string}]}}]}}];
req(describe_acls, 0) ->
  [{resource_type,int8},
   {resource_name,nullable_string},
   {principal,nullable_string},
   {host,nullable_string},
   {operation,int8},
   {permission_type,int8}];
req(create_acls, 0) ->
  [{creations,{array,[{resource_type,int8},
                      {resource_name,string},
                      {principal,string},
                      {host,string},
                      {operation,int8},
                      {permission_type,int8}]}}];
req(delete_acls, 0) ->
  [{filters,{array,[{resource_type,int8},
                    {resource_name,nullable_string},
                    {principal,nullable_string},
                    {host,nullable_string},
                    {operation,int8},
                    {permission_type,int8}]}}];
req(describe_configs, 0) ->
  [{resources,{array,[{resource_type,int8},
                      {resource_name,string},
                      {config_names,{array,string}}]}}];
req(describe_configs, 1) ->
  [{resources,{array,[{resource_type,int8},
                      {resource_name,string},
                      {config_names,{array,string}}]}},
   {include_synonyms,boolean}];
req(alter_configs, 0) ->
  [{resources,
       {array,
           [{resource_type,int8},
            {resource_name,string},
            {config_entries,
                {array,
                    [{config_name,string},{config_value,nullable_string}]}}]}},
   {validate_only,boolean}];
req(alter_replica_log_dirs, 0) ->
  [{log_dirs,{array,[{log_dir,string},
                     {topics,{array,[{topic,string},
                                     {partitions,{array,int32}}]}}]}}];
req(describe_log_dirs, 0) ->
  [{topics,{array,[{topic,string},{partitions,{array,int32}}]}}];
req(sasl_authenticate, 0) ->
  [{sasl_auth_bytes,bytes}];
req(create_partitions, 0) ->
  [{topic_partitions,
       {array,
           [{topic,string},
            {new_partitions,
                [{count,int32},{assignment,{array,{array,int32}}}]}]}},
   {timeout,int32},
   {validate_only,boolean}];
req(create_delegation_token, 0) ->
  [{renewers,{array,[{principal_type,string},{name,string}]}},
   {max_life_time,int64}];
req(renew_delegation_token, 0) ->
  [{hmac,bytes},{renew_time_period,int64}];
req(expire_delegation_token, 0) ->
  [{hmac,bytes},{expiry_time_period,int64}];
req(describe_delegation_token, 0) ->
  [{owners,{array,[{principal_type,string},{name,string}]}}];
req(delete_groups, 0) ->
  [{groups,{array,string}}].

rsp(produce, 0) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {base_offset,int64}]}}]}}];
rsp(produce, 1) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {base_offset,int64}]}}]}},
   {throttle_time_ms,int32}];
rsp(produce, V) when V >= 2, V =< 4 ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {base_offset,int64},
                     {log_append_time,int64}]}}]}},
   {throttle_time_ms,int32}];
rsp(produce, 5) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {base_offset,int64},
                     {log_append_time,int64},
                     {log_start_offset,int64}]}}]}},
   {throttle_time_ms,int32}];
rsp(fetch, 0) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition_header,
                         [{partition,int32},
                          {error_code,int16},
                          {high_watermark,int64}]},
                     {record_set,records}]}}]}}];
rsp(fetch, V) when V >= 1, V =< 3 ->
  [{throttle_time_ms,int32},
   {responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition_header,
                         [{partition,int32},
                          {error_code,int16},
                          {high_watermark,int64}]},
                     {record_set,records}]}}]}}];
rsp(fetch, 4) ->
  [{throttle_time_ms,int32},
   {responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition_header,
                         [{partition,int32},
                          {error_code,int16},
                          {high_watermark,int64},
                          {last_stable_offset,int64},
                          {aborted_transactions,
                              {array,
                                  [{producer_id,int64},
                                   {first_offset,int64}]}}]},
                     {record_set,records}]}}]}}];
rsp(fetch, V) when V >= 5, V =< 6 ->
  [{throttle_time_ms,int32},
   {responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition_header,
                         [{partition,int32},
                          {error_code,int16},
                          {high_watermark,int64},
                          {last_stable_offset,int64},
                          {log_start_offset,int64},
                          {aborted_transactions,
                              {array,
                                  [{producer_id,int64},
                                   {first_offset,int64}]}}]},
                     {record_set,records}]}}]}}];
rsp(fetch, 7) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {session_id,int32},
   {responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition_header,
                         [{partition,int32},
                          {error_code,int16},
                          {high_watermark,int64},
                          {last_stable_offset,int64},
                          {log_start_offset,int64},
                          {aborted_transactions,
                              {array,
                                  [{producer_id,int64},
                                   {first_offset,int64}]}}]},
                     {record_set,records}]}}]}}];
rsp(list_offsets, 0) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {offsets,{array,int64}}]}}]}}];
rsp(list_offsets, 1) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {timestamp,int64},
                     {offset,int64}]}}]}}];
rsp(list_offsets, 2) ->
  [{throttle_time_ms,int32},
   {responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {timestamp,int64},
                     {offset,int64}]}}]}}];
rsp(metadata, 0) ->
  [{brokers,{array,[{node_id,int32},{host,string},{port,int32}]}},
   {topic_metadata,
       {array,
           [{error_code,int16},
            {topic,string},
            {partition_metadata,
                {array,
                    [{error_code,int16},
                     {partition,int32},
                     {leader,int32},
                     {replicas,{array,int32}},
                     {isr,{array,int32}}]}}]}}];
rsp(metadata, 1) ->
  [{brokers,
       {array,
           [{node_id,int32},
            {host,string},
            {port,int32},
            {rack,nullable_string}]}},
   {controller_id,int32},
   {topic_metadata,
       {array,
           [{error_code,int16},
            {topic,string},
            {is_internal,boolean},
            {partition_metadata,
                {array,
                    [{error_code,int16},
                     {partition,int32},
                     {leader,int32},
                     {replicas,{array,int32}},
                     {isr,{array,int32}}]}}]}}];
rsp(metadata, 2) ->
  [{brokers,
       {array,
           [{node_id,int32},
            {host,string},
            {port,int32},
            {rack,nullable_string}]}},
   {cluster_id,nullable_string},
   {controller_id,int32},
   {topic_metadata,
       {array,
           [{error_code,int16},
            {topic,string},
            {is_internal,boolean},
            {partition_metadata,
                {array,
                    [{error_code,int16},
                     {partition,int32},
                     {leader,int32},
                     {replicas,{array,int32}},
                     {isr,{array,int32}}]}}]}}];
rsp(metadata, V) when V >= 3, V =< 4 ->
  [{throttle_time_ms,int32},
   {brokers,
       {array,
           [{node_id,int32},
            {host,string},
            {port,int32},
            {rack,nullable_string}]}},
   {cluster_id,nullable_string},
   {controller_id,int32},
   {topic_metadata,
       {array,
           [{error_code,int16},
            {topic,string},
            {is_internal,boolean},
            {partition_metadata,
                {array,
                    [{error_code,int16},
                     {partition,int32},
                     {leader,int32},
                     {replicas,{array,int32}},
                     {isr,{array,int32}}]}}]}}];
rsp(metadata, 5) ->
  [{throttle_time_ms,int32},
   {brokers,
       {array,
           [{node_id,int32},
            {host,string},
            {port,int32},
            {rack,nullable_string}]}},
   {cluster_id,nullable_string},
   {controller_id,int32},
   {topic_metadata,
       {array,
           [{error_code,int16},
            {topic,string},
            {is_internal,boolean},
            {partition_metadata,
                {array,
                    [{error_code,int16},
                     {partition,int32},
                     {leader,int32},
                     {replicas,{array,int32}},
                     {isr,{array,int32}},
                     {offline_replicas,{array,int32}}]}}]}}];
rsp(offset_commit, V) when V >= 0, V =< 2 ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,[{partition,int32},{error_code,int16}]}}]}}];
rsp(offset_commit, 3) ->
  [{throttle_time_ms,int32},
   {responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,[{partition,int32},{error_code,int16}]}}]}}];
rsp(offset_fetch, V) when V >= 0, V =< 1 ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {offset,int64},
                     {metadata,nullable_string},
                     {error_code,int16}]}}]}}];
rsp(offset_fetch, 2) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {offset,int64},
                     {metadata,nullable_string},
                     {error_code,int16}]}}]}},
   {error_code,int16}];
rsp(offset_fetch, 3) ->
  [{throttle_time_ms,int32},
   {responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {offset,int64},
                     {metadata,nullable_string},
                     {error_code,int16}]}}]}},
   {error_code,int16}];
rsp(find_coordinator, 0) ->
  [{error_code,int16},
   {coordinator,[{node_id,int32},{host,string},{port,int32}]}];
rsp(find_coordinator, 1) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,nullable_string},
   {coordinator,[{node_id,int32},{host,string},{port,int32}]}];
rsp(join_group, V) when V >= 0, V =< 1 ->
  [{error_code,int16},
   {generation_id,int32},
   {group_protocol,string},
   {leader_id,string},
   {member_id,string},
   {members,{array,[{member_id,string},{member_metadata,bytes}]}}];
rsp(join_group, 2) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {generation_id,int32},
   {group_protocol,string},
   {leader_id,string},
   {member_id,string},
   {members,{array,[{member_id,string},{member_metadata,bytes}]}}];
rsp(heartbeat, 0) ->
  [{error_code,int16}];
rsp(heartbeat, 1) ->
  [{throttle_time_ms,int32},{error_code,int16}];
rsp(leave_group, 0) ->
  [{error_code,int16}];
rsp(leave_group, 1) ->
  [{throttle_time_ms,int32},{error_code,int16}];
rsp(sync_group, 0) ->
  [{error_code,int16},{member_assignment,bytes}];
rsp(sync_group, 1) ->
  [{throttle_time_ms,int32},{error_code,int16},{member_assignment,bytes}];
rsp(describe_groups, 0) ->
  [{groups,{array,[{error_code,int16},
                   {group_id,string},
                   {state,string},
                   {protocol_type,string},
                   {protocol,string},
                   {members,{array,[{member_id,string},
                                    {client_id,string},
                                    {client_host,string},
                                    {member_metadata,bytes},
                                    {member_assignment,bytes}]}}]}}];
rsp(describe_groups, 1) ->
  [{throttle_time_ms,int32},
   {groups,{array,[{error_code,int16},
                   {group_id,string},
                   {state,string},
                   {protocol_type,string},
                   {protocol,string},
                   {members,{array,[{member_id,string},
                                    {client_id,string},
                                    {client_host,string},
                                    {member_metadata,bytes},
                                    {member_assignment,bytes}]}}]}}];
rsp(list_groups, 0) ->
  [{error_code,int16},
   {groups,{array,[{group_id,string},{protocol_type,string}]}}];
rsp(list_groups, 1) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {groups,{array,[{group_id,string},{protocol_type,string}]}}];
rsp(sasl_handshake, V) when V >= 0, V =< 1 ->
  [{error_code,int16},{enabled_mechanisms,{array,string}}];
rsp(api_versions, 0) ->
  [{error_code,int16},
   {api_versions,{array,[{api_key,int16},
                         {min_version,int16},
                         {max_version,int16}]}}];
rsp(api_versions, 1) ->
  [{error_code,int16},
   {api_versions,{array,[{api_key,int16},
                         {min_version,int16},
                         {max_version,int16}]}},
   {throttle_time_ms,int32}];
rsp(create_topics, 0) ->
  [{topic_errors,{array,[{topic,string},{error_code,int16}]}}];
rsp(create_topics, 1) ->
  [{topic_errors,{array,[{topic,string},
                         {error_code,int16},
                         {error_message,nullable_string}]}}];
rsp(create_topics, 2) ->
  [{throttle_time_ms,int32},
   {topic_errors,{array,[{topic,string},
                         {error_code,int16},
                         {error_message,nullable_string}]}}];
rsp(delete_topics, 0) ->
  [{topic_error_codes,{array,[{topic,string},{error_code,int16}]}}];
rsp(delete_topics, 1) ->
  [{throttle_time_ms,int32},
   {topic_error_codes,{array,[{topic,string},{error_code,int16}]}}];
rsp(delete_records, 0) ->
  [{throttle_time_ms,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {low_watermark,int64},
                                       {error_code,int16}]}}]}}];
rsp(init_producer_id, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {producer_id,int64},
   {producer_epoch,int16}];
rsp(add_partitions_to_txn, 0) ->
  [{throttle_time_ms,int32},
   {errors,
       {array,
           [{topic,string},
            {partition_errors,
                {array,[{partition,int32},{error_code,int16}]}}]}}];
rsp(add_offsets_to_txn, 0) ->
  [{throttle_time_ms,int32},{error_code,int16}];
rsp(end_txn, 0) ->
  [{throttle_time_ms,int32},{error_code,int16}];
rsp(txn_offset_commit, 0) ->
  [{throttle_time_ms,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {error_code,int16}]}}]}}];
rsp(describe_acls, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,nullable_string},
   {resources,{array,[{resource_type,int8},
                      {resource_name,string},
                      {acls,{array,[{principal,string},
                                    {host,string},
                                    {operation,int8},
                                    {permission_type,int8}]}}]}}];
rsp(create_acls, 0) ->
  [{throttle_time_ms,int32},
   {creation_responses,{array,[{error_code,int16},
                               {error_message,nullable_string}]}}];
rsp(delete_acls, 0) ->
  [{throttle_time_ms,int32},
   {filter_responses,
       {array,
           [{error_code,int16},
            {error_message,nullable_string},
            {matching_acls,
                {array,
                    [{error_code,int16},
                     {error_message,nullable_string},
                     {resource_type,int8},
                     {resource_name,string},
                     {principal,string},
                     {host,string},
                     {operation,int8},
                     {permission_type,int8}]}}]}}];
rsp(describe_configs, 0) ->
  [{throttle_time_ms,int32},
   {resources,
       {array,
           [{error_code,int16},
            {error_message,nullable_string},
            {resource_type,int8},
            {resource_name,string},
            {config_entries,
                {array,
                    [{config_name,string},
                     {config_value,nullable_string},
                     {read_only,boolean},
                     {is_default,boolean},
                     {is_sensitive,boolean}]}}]}}];
rsp(describe_configs, 1) ->
  [{throttle_time_ms,int32},
   {resources,
       {array,
           [{error_code,int16},
            {error_message,nullable_string},
            {resource_type,int8},
            {resource_name,string},
            {config_entries,
                {array,
                    [{config_name,string},
                     {config_value,nullable_string},
                     {read_only,boolean},
                     {config_source,int8},
                     {is_sensitive,boolean},
                     {config_synonyms,
                         {array,
                             [{config_name,string},
                              {config_value,nullable_string},
                              {config_source,int8}]}}]}}]}}];
rsp(alter_configs, 0) ->
  [{throttle_time_ms,int32},
   {resources,{array,[{error_code,int16},
                      {error_message,nullable_string},
                      {resource_type,int8},
                      {resource_name,string}]}}];
rsp(alter_replica_log_dirs, 0) ->
  [{throttle_time_ms,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {error_code,int16}]}}]}}];
rsp(describe_log_dirs, 0) ->
  [{throttle_time_ms,int32},
   {log_dirs,
       {array,
           [{error_code,int16},
            {log_dir,string},
            {topics,
                {array,
                    [{topic,string},
                     {partitions,
                         {array,
                             [{partition,int32},
                              {size,int64},
                              {offset_lag,int64},
                              {is_future,boolean}]}}]}}]}}];
rsp(sasl_authenticate, 0) ->
  [{error_code,int16},{error_message,nullable_string},{sasl_auth_bytes,bytes}];
rsp(create_partitions, 0) ->
  [{throttle_time_ms,int32},
   {topic_errors,{array,[{topic,string},
                         {error_code,int16},
                         {error_message,nullable_string}]}}];
rsp(create_delegation_token, 0) ->
  [{error_code,int16},
   {owner,[{principal_type,string},{name,string}]},
   {issue_timestamp,int64},
   {expiry_timestamp,int64},
   {max_timestamp,int64},
   {token_id,string},
   {hmac,bytes},
   {throttle_time_ms,int32}];
rsp(renew_delegation_token, 0) ->
  [{error_code,int16},{expiry_timestamp,int64},{throttle_time_ms,int32}];
rsp(expire_delegation_token, 0) ->
  [{error_code,int16},{expiry_timestamp,int64},{throttle_time_ms,int32}];
rsp(describe_delegation_token, 0) ->
  [{error_code,int16},
   {token_details,
       {array,
           [{owner,[{principal_type,string},{name,string}]},
            {issue_timestamp,int64},
            {expiry_timestamp,int64},
            {max_timestamp,int64},
            {token_id,string},
            {hmac,bytes},
            {renewers,{array,[{principal_type,string},{name,string}]}}]}},
   {throttle_time_ms,int32}];
rsp(delete_groups, 0) ->
  [{throttle_time_ms,int32},
   {group_error_codes,{array,[{group_id,string},{error_code,int16}]}}].
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
ec(71) -> invalid_fetch_session_epoch.
