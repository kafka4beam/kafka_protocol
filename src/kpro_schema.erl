%% generated code, do not edit!
-module(kpro_schema).
-export([get/3, all_apis/0, vsn_range/1]).

get(produce, req, V) when V >= 0, V =< 2 ->
  [{acks,int16},
   {timeout,int32},
   {topic_data,{array,[{topic,string},
                       {data,{array,[{partition,int32},
                                     {record_set,records}]}}]}}];
get(produce, req, V) when V >= 3, V =< 5 ->
  [{transactional_id,nullable_string},
   {acks,int16},
   {timeout,int32},
   {topic_data,{array,[{topic,string},
                       {data,{array,[{partition,int32},
                                     {record_set,records}]}}]}}];
get(produce, rsp, 0) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {base_offset,int64}]}}]}}];
get(produce, rsp, 1) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {base_offset,int64}]}}]}},
   {throttle_time_ms,int32}];
get(produce, rsp, V) when V >= 2, V =< 4 ->
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
get(produce, rsp, 5) ->
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
get(fetch, req, V) when V >= 0, V =< 2 ->
  [{replica_id,int32},
   {max_wait_time,int32},
   {min_bytes,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {fetch_offset,int64},
                                       {max_bytes,int32}]}}]}}];
get(fetch, req, 3) ->
  [{replica_id,int32},
   {max_wait_time,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {fetch_offset,int64},
                                       {max_bytes,int32}]}}]}}];
get(fetch, req, 4) ->
  [{replica_id,int32},
   {max_wait_time,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {isolation_level,int8},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {fetch_offset,int64},
                                       {max_bytes,int32}]}}]}}];
get(fetch, req, V) when V >= 5, V =< 6 ->
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
get(fetch, rsp, 0) ->
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
get(fetch, rsp, V) when V >= 1, V =< 3 ->
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
get(fetch, rsp, 4) ->
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
get(fetch, rsp, V) when V >= 5, V =< 6 ->
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
get(list_offsets, req, 0) ->
  [{replica_id,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {timestamp,int64},
                                       {max_num_offsets,int32}]}}]}}];
get(list_offsets, req, 1) ->
  [{replica_id,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {timestamp,int64}]}}]}}];
get(list_offsets, req, 2) ->
  [{replica_id,int32},
   {isolation_level,int8},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {timestamp,int64}]}}]}}];
get(list_offsets, rsp, 0) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {offsets,{array,int64}}]}}]}}];
get(list_offsets, rsp, 1) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {timestamp,int64},
                     {offset,int64}]}}]}}];
get(list_offsets, rsp, 2) ->
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
get(metadata, req, V) when V >= 0, V =< 3 ->
  [{topics,{array,string}}];
get(metadata, req, V) when V >= 4, V =< 5 ->
  [{topics,{array,string}},{allow_auto_topic_creation,boolean}];
get(metadata, rsp, 0) ->
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
get(metadata, rsp, 1) ->
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
get(metadata, rsp, 2) ->
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
get(metadata, rsp, V) when V >= 3, V =< 4 ->
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
get(metadata, rsp, 5) ->
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
get(leader_and_isr, req, 0) ->
  [{controller_id,int32},
   {controller_epoch,int32},
   {partition_states,{array,[{topic,string},
                             {partition,int32},
                             {controller_epoch,int32},
                             {leader,int32},
                             {leader_epoch,int32},
                             {isr,{array,int32}},
                             {zk_version,int32},
                             {replicas,{array,int32}}]}},
   {live_leaders,{array,[{id,int32},{host,string},{port,int32}]}}];
get(leader_and_isr, req, 1) ->
  [{controller_id,int32},
   {controller_epoch,int32},
   {partition_states,{array,[{topic,string},
                             {partition,int32},
                             {controller_epoch,int32},
                             {leader,int32},
                             {leader_epoch,int32},
                             {isr,{array,int32}},
                             {zk_version,int32},
                             {replicas,{array,int32}},
                             {is_new,boolean}]}},
   {live_leaders,{array,[{id,int32},{host,string},{port,int32}]}}];
get(leader_and_isr, rsp, V) when V >= 0, V =< 1 ->
  [{error_code,int16},
   {partitions,{array,[{topic,string},{partition,int32},{error_code,int16}]}}];
get(stop_replica, req, 0) ->
  [{controller_id,int32},
   {controller_epoch,int32},
   {delete_partitions,boolean},
   {partitions,{array,[{topic,string},{partition,int32}]}}];
get(stop_replica, rsp, 0) ->
  [{error_code,int16},
   {partitions,{array,[{topic,string},{partition,int32},{error_code,int16}]}}];
get(update_metadata, req, 0) ->
  [{controller_id,int32},
   {controller_epoch,int32},
   {partition_states,{array,[{topic,string},
                             {partition,int32},
                             {controller_epoch,int32},
                             {leader,int32},
                             {leader_epoch,int32},
                             {isr,{array,int32}},
                             {zk_version,int32},
                             {replicas,{array,int32}}]}},
   {live_brokers,{array,[{id,int32},{host,string},{port,int32}]}}];
get(update_metadata, req, 1) ->
  [{controller_id,int32},
   {controller_epoch,int32},
   {partition_states,
       {array,
           [{topic,string},
            {partition,int32},
            {controller_epoch,int32},
            {leader,int32},
            {leader_epoch,int32},
            {isr,{array,int32}},
            {zk_version,int32},
            {replicas,{array,int32}}]}},
   {live_brokers,
       {array,
           [{id,int32},
            {end_points,
                {array,
                    [{port,int32},
                     {host,string},
                     {security_protocol_type,int16}]}}]}}];
get(update_metadata, req, 2) ->
  [{controller_id,int32},
   {controller_epoch,int32},
   {partition_states,
       {array,
           [{topic,string},
            {partition,int32},
            {controller_epoch,int32},
            {leader,int32},
            {leader_epoch,int32},
            {isr,{array,int32}},
            {zk_version,int32},
            {replicas,{array,int32}}]}},
   {live_brokers,
       {array,
           [{id,int32},
            {end_points,
                {array,
                    [{port,int32},
                     {host,string},
                     {security_protocol_type,int16}]}},
            {rack,nullable_string}]}}];
get(update_metadata, req, 3) ->
  [{controller_id,int32},
   {controller_epoch,int32},
   {partition_states,
       {array,
           [{topic,string},
            {partition,int32},
            {controller_epoch,int32},
            {leader,int32},
            {leader_epoch,int32},
            {isr,{array,int32}},
            {zk_version,int32},
            {replicas,{array,int32}}]}},
   {live_brokers,
       {array,
           [{id,int32},
            {end_points,
                {array,
                    [{port,int32},
                     {host,string},
                     {listener_name,string},
                     {security_protocol_type,int16}]}},
            {rack,nullable_string}]}}];
get(update_metadata, req, 4) ->
  [{controller_id,int32},
   {controller_epoch,int32},
   {partition_states,
       {array,
           [{topic,string},
            {partition,int32},
            {controller_epoch,int32},
            {leader,int32},
            {leader_epoch,int32},
            {isr,{array,int32}},
            {zk_version,int32},
            {replicas,{array,int32}},
            {offline_replicas,{array,int32}}]}},
   {live_brokers,
       {array,
           [{id,int32},
            {end_points,
                {array,
                    [{port,int32},
                     {host,string},
                     {listener_name,string},
                     {security_protocol_type,int16}]}},
            {rack,nullable_string}]}}];
get(update_metadata, rsp, V) when V >= 0, V =< 4 ->
  [{error_code,int16}];
get(controlled_shutdown, req, V) when V >= 0, V =< 1 ->
  [{broker_id,int32}];
get(controlled_shutdown, rsp, V) when V >= 0, V =< 1 ->
  [{error_code,int16},
   {partitions_remaining,{array,[{topic,string},{partition,int32}]}}];
get(offset_commit, req, 0) ->
  [{group_id,string},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {offset,int64},
                                       {metadata,nullable_string}]}}]}}];
get(offset_commit, req, 1) ->
  [{group_id,string},
   {generation_id,int32},
   {member_id,string},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {offset,int64},
                                       {timestamp,int64},
                                       {metadata,nullable_string}]}}]}}];
get(offset_commit, req, V) when V >= 2, V =< 3 ->
  [{group_id,string},
   {generation_id,int32},
   {member_id,string},
   {retention_time,int64},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {offset,int64},
                                       {metadata,nullable_string}]}}]}}];
get(offset_commit, rsp, V) when V >= 0, V =< 2 ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,[{partition,int32},{error_code,int16}]}}]}}];
get(offset_commit, rsp, 3) ->
  [{throttle_time_ms,int32},
   {responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,[{partition,int32},{error_code,int16}]}}]}}];
get(offset_fetch, req, V) when V >= 0, V =< 3 ->
  [{group_id,string},
   {topics,{array,[{topic,string},{partitions,{array,[{partition,int32}]}}]}}];
get(offset_fetch, rsp, V) when V >= 0, V =< 1 ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {offset,int64},
                     {metadata,nullable_string},
                     {error_code,int16}]}}]}}];
get(offset_fetch, rsp, 2) ->
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
get(offset_fetch, rsp, 3) ->
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
get(find_coordinator, req, 0) ->
  [{group_id,string}];
get(find_coordinator, req, 1) ->
  [{coordinator_key,string},{coordinator_type,int8}];
get(find_coordinator, rsp, 0) ->
  [{error_code,int16},
   {coordinator,[{node_id,int32},{host,string},{port,int32}]}];
get(find_coordinator, rsp, 1) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,nullable_string},
   {coordinator,[{node_id,int32},{host,string},{port,int32}]}];
get(join_group, req, 0) ->
  [{group_id,string},
   {session_timeout,int32},
   {member_id,string},
   {protocol_type,string},
   {group_protocols,{array,[{protocol_name,string},
                            {protocol_metadata,bytes}]}}];
get(join_group, req, V) when V >= 1, V =< 2 ->
  [{group_id,string},
   {session_timeout,int32},
   {rebalance_timeout,int32},
   {member_id,string},
   {protocol_type,string},
   {group_protocols,{array,[{protocol_name,string},
                            {protocol_metadata,bytes}]}}];
get(join_group, rsp, V) when V >= 0, V =< 1 ->
  [{error_code,int16},
   {generation_id,int32},
   {group_protocol,string},
   {leader_id,string},
   {member_id,string},
   {members,{array,[{member_id,string},{member_metadata,bytes}]}}];
get(join_group, rsp, 2) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {generation_id,int32},
   {group_protocol,string},
   {leader_id,string},
   {member_id,string},
   {members,{array,[{member_id,string},{member_metadata,bytes}]}}];
get(heartbeat, req, V) when V >= 0, V =< 1 ->
  [{group_id,string},{generation_id,int32},{member_id,string}];
get(heartbeat, rsp, 0) ->
  [{error_code,int16}];
get(heartbeat, rsp, 1) ->
  [{throttle_time_ms,int32},{error_code,int16}];
get(leave_group, req, V) when V >= 0, V =< 1 ->
  [{group_id,string},{member_id,string}];
get(leave_group, rsp, 0) ->
  [{error_code,int16}];
get(leave_group, rsp, 1) ->
  [{throttle_time_ms,int32},{error_code,int16}];
get(sync_group, req, V) when V >= 0, V =< 1 ->
  [{group_id,string},
   {generation_id,int32},
   {member_id,string},
   {group_assignment,{array,[{member_id,string},{member_assignment,bytes}]}}];
get(sync_group, rsp, 0) ->
  [{error_code,int16},{member_assignment,bytes}];
get(sync_group, rsp, 1) ->
  [{throttle_time_ms,int32},{error_code,int16},{member_assignment,bytes}];
get(describe_groups, req, V) when V >= 0, V =< 1 ->
  [{group_ids,{array,string}}];
get(describe_groups, rsp, 0) ->
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
get(describe_groups, rsp, 1) ->
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
get(list_groups, req, V) when V >= 0, V =< 1 ->
  [];
get(list_groups, rsp, 0) ->
  [{error_code,int16},
   {groups,{array,[{group_id,string},{protocol_type,string}]}}];
get(list_groups, rsp, 1) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {groups,{array,[{group_id,string},{protocol_type,string}]}}];
get(sasl_handshake, req, V) when V >= 0, V =< 1 ->
  [{mechanism,string}];
get(sasl_handshake, rsp, V) when V >= 0, V =< 1 ->
  [{error_code,int16},{enabled_mechanisms,{array,string}}];
get(api_versions, req, V) when V >= 0, V =< 1 ->
  [];
get(api_versions, rsp, 0) ->
  [{error_code,int16},
   {api_versions,{array,[{api_key,int16},
                         {min_version,int16},
                         {max_version,int16}]}}];
get(api_versions, rsp, 1) ->
  [{error_code,int16},
   {api_versions,{array,[{api_key,int16},
                         {min_version,int16},
                         {max_version,int16}]}},
   {throttle_time_ms,int32}];
get(create_topics, req, 0) ->
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
get(create_topics, req, V) when V >= 1, V =< 2 ->
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
get(create_topics, rsp, 0) ->
  [{topic_errors,{array,[{topic,string},{error_code,int16}]}}];
get(create_topics, rsp, 1) ->
  [{topic_errors,{array,[{topic,string},
                         {error_code,int16},
                         {error_message,nullable_string}]}}];
get(create_topics, rsp, 2) ->
  [{throttle_time_ms,int32},
   {topic_errors,{array,[{topic,string},
                         {error_code,int16},
                         {error_message,nullable_string}]}}];
get(delete_topics, req, V) when V >= 0, V =< 1 ->
  [{topics,{array,string}},{timeout,int32}];
get(delete_topics, rsp, 0) ->
  [{topic_error_codes,{array,[{topic,string},{error_code,int16}]}}];
get(delete_topics, rsp, 1) ->
  [{throttle_time_ms,int32},
   {topic_error_codes,{array,[{topic,string},{error_code,int16}]}}];
get(delete_records, req, 0) ->
  [{topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},{offset,int64}]}}]}},
   {timeout,int32}];
get(delete_records, rsp, 0) ->
  [{throttle_time_ms,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {low_watermark,int64},
                                       {error_code,int16}]}}]}}];
get(init_producer_id, req, 0) ->
  [{transactional_id,nullable_string},{transaction_timeout_ms,int32}];
get(init_producer_id, rsp, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {producer_id,int64},
   {producer_epoch,int16}];
get(offset_for_leader_epoch, req, 0) ->
  [{topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {leader_epoch,int32}]}}]}}];
get(offset_for_leader_epoch, rsp, 0) ->
  [{topics,{array,[{topic,string},
                   {partitions,{array,[{error_code,int16},
                                       {partition,int32},
                                       {end_offset,int64}]}}]}}];
get(add_partitions_to_txn, req, 0) ->
  [{transactional_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {topics,{array,[{topic,string},{partitions,{array,int32}}]}}];
get(add_partitions_to_txn, rsp, 0) ->
  [{throttle_time_ms,int32},
   {errors,
       {array,
           [{topic,string},
            {partition_errors,
                {array,[{partition,int32},{error_code,int16}]}}]}}];
get(add_offsets_to_txn, req, 0) ->
  [{transactional_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {group_id,string}];
get(add_offsets_to_txn, rsp, 0) ->
  [{throttle_time_ms,int32},{error_code,int16}];
get(end_txn, req, 0) ->
  [{transactional_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {transaction_result,boolean}];
get(end_txn, rsp, 0) ->
  [{throttle_time_ms,int32},{error_code,int16}];
get(write_txn_markers, req, 0) ->
  [{transaction_markers,
       {array,
           [{producer_id,int64},
            {producer_epoch,int16},
            {transaction_result,boolean},
            {topics,{array,[{topic,string},{partitions,{array,int32}}]}},
            {coordinator_epoch,int32}]}}];
get(write_txn_markers, rsp, 0) ->
  [{transaction_markers,
       {array,
           [{producer_id,int64},
            {topics,
                {array,
                    [{topic,string},
                     {partitions,
                         {array,
                             [{partition,int32},{error_code,int16}]}}]}}]}}];
get(txn_offset_commit, req, 0) ->
  [{transactional_id,string},
   {group_id,string},
   {producer_id,int64},
   {producer_epoch,int16},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {offset,int64},
                                       {metadata,nullable_string}]}}]}}];
get(txn_offset_commit, rsp, 0) ->
  [{throttle_time_ms,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {error_code,int16}]}}]}}];
get(describe_acls, req, 0) ->
  [{resource_type,int8},
   {resource_name,nullable_string},
   {principal,nullable_string},
   {host,nullable_string},
   {operation,int8},
   {permission_type,int8}];
get(describe_acls, rsp, 0) ->
  [{throttle_time_ms,int32},
   {error_code,int16},
   {error_message,nullable_string},
   {resources,{array,[{resource_type,int8},
                      {resource_name,string},
                      {acls,{array,[{principal,string},
                                    {host,string},
                                    {operation,int8},
                                    {permission_type,int8}]}}]}}];
get(create_acls, req, 0) ->
  [{creations,{array,[{resource_type,int8},
                      {resource_name,string},
                      {principal,string},
                      {host,string},
                      {operation,int8},
                      {permission_type,int8}]}}];
get(create_acls, rsp, 0) ->
  [{throttle_time_ms,int32},
   {creation_responses,{array,[{error_code,int16},
                               {error_message,nullable_string}]}}];
get(delete_acls, req, 0) ->
  [{filters,{array,[{resource_type,int8},
                    {resource_name,nullable_string},
                    {principal,nullable_string},
                    {host,nullable_string},
                    {operation,int8},
                    {permission_type,int8}]}}];
get(delete_acls, rsp, 0) ->
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
get(describe_configs, req, 0) ->
  [{resources,{array,[{resource_type,int8},
                      {resource_name,string},
                      {config_names,{array,string}}]}}];
get(describe_configs, rsp, 0) ->
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
get(alter_configs, req, 0) ->
  [{resources,
       {array,
           [{resource_type,int8},
            {resource_name,string},
            {config_entries,
                {array,
                    [{config_name,string},{config_value,nullable_string}]}}]}},
   {validate_only,boolean}];
get(alter_configs, rsp, 0) ->
  [{throttle_time_ms,int32},
   {resources,{array,[{error_code,int16},
                      {error_message,nullable_string},
                      {resource_type,int8},
                      {resource_name,string}]}}];
get(alter_replica_log_dirs, req, 0) ->
  [{log_dirs,{array,[{log_dir,string},
                     {topics,{array,[{topic,string},
                                     {partitions,{array,int32}}]}}]}}];
get(alter_replica_log_dirs, rsp, 0) ->
  [{throttle_time_ms,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {error_code,int16}]}}]}}];
get(describe_log_dirs, req, 0) ->
  [{topics,{array,[{topic,string},{partitions,{array,int32}}]}}];
get(describe_log_dirs, rsp, 0) ->
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
get(sasl_authenticate, req, 0) ->
  [{sasl_auth_bytes,bytes}];
get(sasl_authenticate, rsp, 0) ->
  [{error_code,int16},{error_message,nullable_string},{sasl_auth_bytes,bytes}];
get(create_partitions, req, 0) ->
  [{topic_partitions,
       {array,
           [{topic,string},
            {new_partitions,
                [{count,int32},{assignment,{array,{array,int32}}}]}]}},
   {timeout,int32},
   {validate_only,boolean}];
get(create_partitions, rsp, 0) ->
  [{throttle_time_ms,int32},
   {topic_errors,{array,[{topic,string},
                         {error_code,int16},
                         {error_message,nullable_string}]}}].
all_apis() ->
[add_offsets_to_txn,
add_partitions_to_txn,
alter_configs,
alter_replica_log_dirs,
api_versions,
controlled_shutdown,
create_acls,
create_partitions,
create_topics,
delete_acls,
delete_records,
delete_topics,
describe_acls,
describe_configs,
describe_groups,
describe_log_dirs,
end_txn,
fetch,
find_coordinator,
heartbeat,
init_producer_id,
join_group,
leader_and_isr,
leave_group,
list_groups,
list_offsets,
metadata,
offset_commit,
offset_fetch,
offset_for_leader_epoch,
produce,
sasl_authenticate,
sasl_handshake,
stop_replica,
sync_group,
txn_offset_commit,
update_metadata,
write_txn_markers].

vsn_range(produce) -> {0, 5};
vsn_range(fetch) -> {0, 6};
vsn_range(list_offsets) -> {0, 2};
vsn_range(metadata) -> {0, 5};
vsn_range(leader_and_isr) -> {0, 1};
vsn_range(stop_replica) -> {0, 0};
vsn_range(update_metadata) -> {0, 4};
vsn_range(controlled_shutdown) -> {0, 1};
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
vsn_range(offset_for_leader_epoch) -> {0, 0};
vsn_range(add_partitions_to_txn) -> {0, 0};
vsn_range(add_offsets_to_txn) -> {0, 0};
vsn_range(end_txn) -> {0, 0};
vsn_range(write_txn_markers) -> {0, 0};
vsn_range(txn_offset_commit) -> {0, 0};
vsn_range(describe_acls) -> {0, 0};
vsn_range(create_acls) -> {0, 0};
vsn_range(delete_acls) -> {0, 0};
vsn_range(describe_configs) -> {0, 0};
vsn_range(alter_configs) -> {0, 0};
vsn_range(alter_replica_log_dirs) -> {0, 0};
vsn_range(describe_log_dirs) -> {0, 0};
vsn_range(sasl_authenticate) -> {0, 0};
vsn_range(create_partitions) -> {0, 0}.

