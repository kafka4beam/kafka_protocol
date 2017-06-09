%% generated code, do not edit!
-module(kpro_schema).
-export([get/2]).

get(produce_request, V) when V >= 0, V =< 2 ->
  [{acks,int16},
   {timeout,int32},
   {topic_data,{array,[{topic,string},
                       {data,{array,[{partition,int32},
                                     {record_set,records}]}}]}}];
get(produce_response, 0) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {base_offset,int64}]}}]}}];
get(produce_response, 1) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {base_offset,int64}]}}]}},
   {throttle_time_ms,int32}];
get(produce_response, 2) ->
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
get(fetch_request, V) when V >= 0, V =< 2 ->
  [{replica_id,int32},
   {max_wait_time,int32},
   {min_bytes,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {fetch_offset,int64},
                                       {max_bytes,int32}]}}]}}];
get(fetch_request, 3) ->
  [{replica_id,int32},
   {max_wait_time,int32},
   {min_bytes,int32},
   {max_bytes,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {fetch_offset,int64},
                                       {max_bytes,int32}]}}]}}];
get(fetch_response, 0) ->
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
get(fetch_response, V) when V >= 1, V =< 3 ->
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
get(offsets_request, 0) ->
  [{replica_id,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {timestamp,int64},
                                       {max_num_offsets,int32}]}}]}}];
get(offsets_request, 1) ->
  [{replica_id,int32},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {timestamp,int64}]}}]}}];
get(offsets_response, 0) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {offsets,{array,int64}}]}}]}}];
get(offsets_response, 1) ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {error_code,int16},
                     {timestamp,int64},
                     {offset,int64}]}}]}}];
get(metadata_request, V) when V >= 0, V =< 2 ->
  [{topics,{array,string}}];
get(metadata_response, 0) ->
  [{brokers,{array,[{node_id,int32},{host,string},{port,int32}]}},
   {topic_metadata,
       {array,
           [{topic_error_code,int16},
            {topic,string},
            {partition_metadata,
                {array,
                    [{partition_error_code,int16},
                     {partition_id,int32},
                     {leader,int32},
                     {replicas,{array,int32}},
                     {isr,{array,int32}}]}}]}}];
get(metadata_response, 1) ->
  [{brokers,
       {array,
           [{node_id,int32},
            {host,string},
            {port,int32},
            {rack,nullable_string}]}},
   {controller_id,int32},
   {topic_metadata,
       {array,
           [{topic_error_code,int16},
            {topic,string},
            {is_internal,boolean},
            {partition_metadata,
                {array,
                    [{partition_error_code,int16},
                     {partition_id,int32},
                     {leader,int32},
                     {replicas,{array,int32}},
                     {isr,{array,int32}}]}}]}}];
get(metadata_response, 2) ->
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
           [{topic_error_code,int16},
            {topic,string},
            {is_internal,boolean},
            {partition_metadata,
                {array,
                    [{partition_error_code,int16},
                     {partition_id,int32},
                     {leader,int32},
                     {replicas,{array,int32}},
                     {isr,{array,int32}}]}}]}}];
get(leader_and_isr_request, 0) ->
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
get(leader_and_isr_response, 0) ->
  [{error_code,int16},
   {partitions,{array,[{topic,string},{partition,int32},{error_code,int16}]}}];
get(stop_replica_request, 0) ->
  [{controller_id,int32},
   {controller_epoch,int32},
   {delete_partitions,boolean},
   {partitions,{array,[{topic,string},{partition,int32}]}}];
get(stop_replica_response, 0) ->
  [{error_code,int16},
   {partitions,{array,[{topic,string},{partition,int32},{error_code,int16}]}}];
get(update_metadata_request, 0) ->
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
get(update_metadata_request, 1) ->
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
get(update_metadata_request, 2) ->
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
get(update_metadata_request, 3) ->
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
get(update_metadata_response, V) when V >= 0, V =< 3 ->
  [{error_code,int16}];
get(controlled_shutdown_request, 1) ->
  [{broker_id,int32}];
get(controlled_shutdown_response, 1) ->
  [{error_code,int16},
   {partitions_remaining,{array,[{topic,string},{partition,int32}]}}];
get(offset_commit_request, 0) ->
  [{group_id,string},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {offset,int64},
                                       {metadata,nullable_string}]}}]}}];
get(offset_commit_request, 1) ->
  [{group_id,string},
   {group_generation_id,int32},
   {member_id,string},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {offset,int64},
                                       {timestamp,int64},
                                       {metadata,nullable_string}]}}]}}];
get(offset_commit_request, 2) ->
  [{group_id,string},
   {group_generation_id,int32},
   {member_id,string},
   {retention_time,int64},
   {topics,{array,[{topic,string},
                   {partitions,{array,[{partition,int32},
                                       {offset,int64},
                                       {metadata,nullable_string}]}}]}}];
get(offset_commit_response, V) when V >= 0, V =< 2 ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,[{partition,int32},{error_code,int16}]}}]}}];
get(offset_fetch_request, V) when V >= 0, V =< 2 ->
  [{group_id,string},
   {topics,{array,[{topic,string},{partitions,{array,[{partition,int32}]}}]}}];
get(offset_fetch_response, V) when V >= 0, V =< 1 ->
  [{responses,
       {array,
           [{topic,string},
            {partition_responses,
                {array,
                    [{partition,int32},
                     {offset,int64},
                     {metadata,nullable_string},
                     {error_code,int16}]}}]}}];
get(offset_fetch_response, 2) ->
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
get(group_coordinator_request, 0) ->
  [{group_id,string}];
get(group_coordinator_response, 0) ->
  [{error_code,int16},
   {coordinator,[{node_id,int32},{host,string},{port,int32}]}];
get(join_group_request, 0) ->
  [{group_id,string},
   {session_timeout,int32},
   {member_id,string},
   {protocol_type,string},
   {group_protocols,{array,[{protocol_name,string},
                            {protocol_metadata,bytes}]}}];
get(join_group_request, 1) ->
  [{group_id,string},
   {session_timeout,int32},
   {rebalance_timeout,int32},
   {member_id,string},
   {protocol_type,string},
   {group_protocols,{array,[{protocol_name,string},
                            {protocol_metadata,bytes}]}}];
get(join_group_response, V) when V >= 0, V =< 1 ->
  [{error_code,int16},
   {generation_id,int32},
   {group_protocol,string},
   {leader_id,string},
   {member_id,string},
   {members,{array,[{member_id,string},{member_metadata,bytes}]}}];
get(heartbeat_request, 0) ->
  [{group_id,string},{group_generation_id,int32},{member_id,string}];
get(heartbeat_response, 0) ->
  [{error_code,int16}];
get(leave_group_request, 0) ->
  [{group_id,string},{member_id,string}];
get(leave_group_response, 0) ->
  [{error_code,int16}];
get(sync_group_request, 0) ->
  [{group_id,string},
   {generation_id,int32},
   {member_id,string},
   {group_assignment,{array,[{member_id,string},{member_assignment,bytes}]}}];
get(sync_group_response, 0) ->
  [{error_code,int16},{member_assignment,bytes}];
get(describe_groups_request, 0) ->
  [{group_ids,{array,string}}];
get(describe_groups_response, 0) ->
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
get(list_groups_request, 0) ->
  [];
get(list_groups_response, 0) ->
  [{error_code,int16},
   {groups,{array,[{group_id,string},{protocol_type,string}]}}];
get(sasl_handshake_request, 0) ->
  [{mechanism,string}];
get(sasl_handshake_response, 0) ->
  [{error_code,int16},{enabled_mechanisms,{array,string}}];
get(api_versions_request, 0) ->
  [];
get(api_versions_response, 0) ->
  [{error_code,int16},
   {api_versions,{array,[{api_key,int16},
                         {min_version,int16},
                         {max_version,int16}]}}];
get(create_topics_request, 0) ->
  [{create_topic_requests,
       {array,
           [{topic,string},
            {num_partitions,int32},
            {replication_factor,int16},
            {replica_assignment,
                {array,[{partition_id,int32},{replicas,{array,int32}}]}},
            {configs,{array,[{config_key,string},{config_value,string}]}}]}},
   {timeout,int32}];
get(create_topics_request, 1) ->
  [{create_topic_requests,
       {array,
           [{topic,string},
            {num_partitions,int32},
            {replication_factor,int16},
            {replica_assignment,
                {array,[{partition_id,int32},{replicas,{array,int32}}]}},
            {configs,{array,[{config_key,string},{config_value,string}]}}]}},
   {timeout,int32},
   {validate_only,boolean}];
get(create_topics_response, 0) ->
  [{topic_errors,{array,[{topic,string},{error_code,int16}]}}];
get(create_topics_response, 1) ->
  [{topic_errors,{array,[{topic,string},
                         {error_code,int16},
                         {error_message,nullable_string}]}}];
get(delete_topics_request, 0) ->
  [{topics,{array,string}},{timeout,int32}];
get(delete_topics_response, 0) ->
  [{topic_error_codes,{array,[{topic,string},{error_code,int16}]}}].

