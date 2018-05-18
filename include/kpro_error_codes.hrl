%% Generated code, do not edit!

-ifndef(KPRO_ERROR_CODES_HRL).
-define(KPRO_ERROR_CODES_HRL, true).

-define(no_error,
        no_error). % 0
-define(unknown_server_error,
        unknown_server_error). % -1
-define(offset_out_of_range,
        offset_out_of_range). % 1
-define(corrupt_message,
        corrupt_message). % 2
-define(unknown_topic_or_partition,
        unknown_topic_or_partition). % 3
-define(invalid_fetch_size,
        invalid_fetch_size). % 4
-define(leader_not_available,
        leader_not_available). % 5
-define(not_leader_for_partition,
        not_leader_for_partition). % 6
-define(request_timed_out,
        request_timed_out). % 7
-define(broker_not_available,
        broker_not_available). % 8
-define(replica_not_available,
        replica_not_available). % 9
-define(message_too_large,
        message_too_large). % 10
-define(stale_controller_epoch,
        stale_controller_epoch). % 11
-define(offset_metadata_too_large,
        offset_metadata_too_large). % 12
-define(network_exception,
        network_exception). % 13
-define(coordinator_load_in_progress,
        coordinator_load_in_progress). % 14
-define(coordinator_not_available,
        coordinator_not_available). % 15
-define(not_coordinator,
        not_coordinator). % 16
-define(invalid_topic_exception,
        invalid_topic_exception). % 17
-define(record_list_too_large,
        record_list_too_large). % 18
-define(not_enough_replicas,
        not_enough_replicas). % 19
-define(not_enough_replicas_after_append,
        not_enough_replicas_after_append). % 20
-define(invalid_required_acks,
        invalid_required_acks). % 21
-define(illegal_generation,
        illegal_generation). % 22
-define(inconsistent_group_protocol,
        inconsistent_group_protocol). % 23
-define(invalid_group_id,
        invalid_group_id). % 24
-define(unknown_member_id,
        unknown_member_id). % 25
-define(invalid_session_timeout,
        invalid_session_timeout). % 26
-define(rebalance_in_progress,
        rebalance_in_progress). % 27
-define(invalid_commit_offset_size,
        invalid_commit_offset_size). % 28
-define(topic_authorization_failed,
        topic_authorization_failed). % 29
-define(group_authorization_failed,
        group_authorization_failed). % 30
-define(cluster_authorization_failed,
        cluster_authorization_failed). % 31
-define(invalid_timestamp,
        invalid_timestamp). % 32
-define(unsupported_sasl_mechanism,
        unsupported_sasl_mechanism). % 33
-define(illegal_sasl_state,
        illegal_sasl_state). % 34
-define(unsupported_version,
        unsupported_version). % 35
-define(topic_already_exists,
        topic_already_exists). % 36
-define(invalid_partitions,
        invalid_partitions). % 37
-define(invalid_replication_factor,
        invalid_replication_factor). % 38
-define(invalid_replica_assignment,
        invalid_replica_assignment). % 39
-define(invalid_config,
        invalid_config). % 40
-define(not_controller,
        not_controller). % 41
-define(invalid_request,
        invalid_request). % 42
-define(unsupported_for_message_format,
        unsupported_for_message_format). % 43
-define(policy_violation,
        policy_violation). % 44
-define(out_of_order_sequence_number,
        out_of_order_sequence_number). % 45
-define(duplicate_sequence_number,
        duplicate_sequence_number). % 46
-define(invalid_producer_epoch,
        invalid_producer_epoch). % 47
-define(invalid_txn_state,
        invalid_txn_state). % 48
-define(invalid_producer_id_mapping,
        invalid_producer_id_mapping). % 49
-define(invalid_transaction_timeout,
        invalid_transaction_timeout). % 50
-define(concurrent_transactions,
        concurrent_transactions). % 51
-define(transaction_coordinator_fenced,
        transaction_coordinator_fenced). % 52
-define(transactional_id_authorization_failed,
        transactional_id_authorization_failed). % 53
-define(security_disabled,
        security_disabled). % 54
-define(operation_not_attempted,
        operation_not_attempted). % 55
-define(kafka_storage_error,
        kafka_storage_error). % 56
-define(log_dir_not_found,
        log_dir_not_found). % 57
-define(sasl_authentication_failed,
        sasl_authentication_failed). % 58
-define(unknown_producer_id,
        unknown_producer_id). % 59
-define(reassignment_in_progress,
        reassignment_in_progress). % 60
-define(delegation_token_auth_disabled,
        delegation_token_auth_disabled). % 61
-define(delegation_token_not_found,
        delegation_token_not_found). % 62
-define(delegation_token_owner_mismatch,
        delegation_token_owner_mismatch). % 63
-define(delegation_token_request_not_allowed,
        delegation_token_request_not_allowed). % 64
-define(delegation_token_authorization_failed,
        delegation_token_authorization_failed). % 65
-define(delegation_token_expired,
        delegation_token_expired). % 66
-define(invalid_principal_type,
        invalid_principal_type). % 67
-define(non_empty_group,
        non_empty_group). % 68
-define(group_id_not_found,
        group_id_not_found). % 69
-define(fetch_session_id_not_found,
        fetch_session_id_not_found). % 70
-define(invalid_fetch_session_epoch,
        invalid_fetch_session_epoch). % 71

-endif.
