%%%   Copyright (c) 2014-2016, Klarna AB
%%%
%%%   Licensed under the Apache License, Version 2.0 (the "License");
%%%   you may not use this file except in compliance with the License.
%%%   You may obtain a copy of the License at
%%%
%%%       http://www.apache.org/licenses/LICENSE-2.0
%%%
%%%   Unless required by applicable law or agreed to in writing, software
%%%   distributed under the License is distributed on an "AS IS" BASIS,
%%%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%%   See the License for the specific language governing permissions and
%%%   limitations under the License.
%%%

%% common header file for code generation and generated code.

-ifndef(kpro_common_hrl).
-define(kpro_common_hrl, true).

-ifndef(KAFKA_VERSION).
-define(KAFKA_VERSION, {0,10,1}). %% by default
-endif.

-type kpro_compress_option() :: no_compression | gzip | snappy | lz4.

%% Compression attributes
-define(KPRO_COMPRESS_NONE,   0).
-define(KPRO_COMPRESS_GZIP,   1).
-define(KPRO_COMPRESS_SNAPPY, 2).
-define(KPRO_COMPRESS_LZ4,    3).

-define(KPRO_COMPRESSION_MASK, 7).
-define(KPRO_IS_GZIP_ATTR(ATTR),
        ((?KPRO_COMPRESSION_MASK band ATTR) =:= ?KPRO_COMPRESS_GZIP)).
-define(KPRO_IS_SNAPPY_ATTR(ATTR),
        ((?KPRO_COMPRESSION_MASK band ATTR) =:= ?KPRO_COMPRESS_SNAPPY)).
-define(KPRO_IS_LZ4_ATTR(ATTR),
        ((?KPRO_COMPRESSION_MASK band ATTR) =:= ?KPRO_COMPRESS_LZ4)).

%% some pre-defined default values
-define(KPRO_REPLICA_ID, -1).
-define(KPRO_API_VERSION, 0).
-define(KPRO_MAGIC_BYTE, 0).
-define(KPRO_ATTRIBUTES, ?KPRO_COMPRESS_NONE).

%% correlation IDs are 32 bit signed integers.
%% we use 25 bits only, and use the highest 5 bits to be redudant with API key
%% and next 2 bits with API version
%% so that the decoder may decode the responses without the need of an extra
%% correlation ID to API key association.
-define(API_KEY_BITS, 5).
-define(API_VERSION_BITS, 2).
-define(CORR_ID_BITS, 25).
-define(MAX_CORR_ID, 33554431).


-define(incomplete_message, incomplete_message).

-define(IS_KAFKA_PRIMITIVE(T),
        (T =:= boolean orelse T =:= int8 orelse T =:= int16 orelse
         T =:= int32 orelse T =:= int64 orelse
         T =:= string orelse T =:= nullable_string orelse
         T =:= bytes orelse T =:= records)).

%% TODO generate it from java code somehow
-define(REQ_TO_API_KEY_AND_VERSION(Req),
        case Req of
          kpro_produce_request_v0             -> { 0, 0};
          kpro_produce_request_v1             -> { 0, 1};
          kpro_produce_request_v2             -> { 0, 2};
          kpro_fetch_request_v0               -> { 1, 0};
          kpro_fetch_request_v1               -> { 1, 1};
          kpro_fetch_request_v2               -> { 1, 2};
          kpro_fetch_request_v3               -> { 1, 3};
          kpro_offsets_request_v0             -> { 2, 0};
          kpro_offsets_request_v1             -> { 2, 1};
          kpro_metadata_request_v0            -> { 3, 0};
          kpro_metadata_request_v1            -> { 3, 1};
          kpro_metadata_request_v2            -> { 3, 2};
          kpro_leader_and_isr_request_v0      -> { 4, 0};
          kpro_stop_replica_request_v0        -> { 5, 0};
          kpro_update_metadata_request_v0     -> { 6, 0};
          kpro_update_metadata_request_v1     -> { 6, 1};
          kpro_update_metadata_request_v2     -> { 6, 2};
          kpro_controlled_shutdown_request_v1 -> { 7, 1};
          kpro_offset_commit_request_v0       -> { 8, 0};
          kpro_offset_commit_request_v1       -> { 8, 1};
          kpro_offset_commit_request_v2       -> { 8, 2};
          kpro_offset_fetch_request_v0        -> { 9, 0};
          kpro_offset_fetch_request_v1        -> { 9, 1};
          kpro_offset_fetch_request_v2        -> { 9, 2};
          kpro_group_coordinator_request_v0   -> {10, 0};
          kpro_join_group_request_v0          -> {11, 0};
          kpro_join_group_request_v1          -> {11, 1};
          kpro_heartbeat_request_v0           -> {12, 0};
          kpro_leave_group_request_v0         -> {13, 0};
          kpro_sync_group_request_v0          -> {14, 0};
          kpro_describe_groups_request_v0     -> {15, 0};
          kpro_list_groups_request_v0         -> {16, 0};
          kpro_sasl_handshake_request_v0      -> {17, 0};
          kpro_api_versions_request_v0        -> {18, 0};
          kpro_create_topics_request_v0       -> {19, 0};
          kpro_create_topics_request_v1       -> {19, 1};
          kpro_delete_topics_request_v0       -> {20, 0}
        end).

-define(API_KEY_AND_VERSION_TO_RSP(ApiKey, ApiVersion),
        case {ApiKey, ApiVersion} of
          { 0, 0} -> kpro_produce_response_v0;
          { 0, 1} -> kpro_produce_response_v1;
          { 0, 2} -> kpro_produce_response_v2;
          { 1, 0} -> kpro_fetch_response_v0;
          { 1, 1} -> kpro_fetch_response_v1;
          { 1, 2} -> kpro_fetch_response_v2;
          { 1, 3} -> kpro_fetch_response_v3;
          { 2, 0} -> kpro_offsets_response_v0;
          { 2, 1} -> kpro_offsets_response_v1;
          { 3, 0} -> kpro_metadata_response_v0;
          { 3, 1} -> kpro_metadata_response_v1;
          { 3, 2} -> kpro_metadata_response_v2;
          { 4, 0} -> kpro_leader_and_isr_response_v0;
          { 5, 0} -> kpro_stop_replica_response_v0;
          { 6, 0} -> kpro_update_metadata_response_v0;
          { 6, 1} -> kpro_update_metadata_response_v1;
          { 6, 2} -> kpro_update_metadata_response_v2;
          { 7, 1} -> kpro_controlled_shutdown_response_v1;
          { 8, 0} -> kpro_offset_commit_response_v0;
          { 8, 1} -> kpro_offset_commit_response_v1;
          { 8, 2} -> kpro_offset_commit_response_v2;
          { 9, 0} -> kpro_offset_fetch_response_v0;
          { 9, 1} -> kpro_offset_fetch_response_v1;
          { 9, 2} -> kpro_offset_fetch_response_v2;
          {10, 0} -> kpro_group_coordinator_response_v0;
          {11, 0} -> kpro_join_group_response_v0;
          {11, 1} -> kpro_join_group_response_v1;
          {12, 0} -> kpro_heartbeat_response_v0;
          {13, 0} -> kpro_leave_group_response_v0;
          {14, 0} -> kpro_sync_group_response_v0;
          {15, 0} -> kpro_describe_groups_response_v0;
          {16, 0} -> kpro_list_groups_response_v0;
          {17, 0} -> kpro_sasl_handshake_response_v0;
          {18, 0} -> kpro_api_versions_response_v0;
          {19, 0} -> kpro_create_topics_response_v0;
          {19, 1} -> kpro_create_topics_response_v1;
          {20, 0} -> kpro_delete_topics_response_v0
        end).

%% Error code macros, from:
%% https://github.com/apache/kafka/blob/0.9.0/clients/src/
%%       main/java/org/apache/kafka/common/protocol/Errors.java

-define(EC_UNKNOWN,                      'UnknownError').                   % -1
-define(EC_NONE,                         'no_error').                       %  0
-define(EC_OFFSET_OUT_OF_RANGE,          'OffsetOutOfRange').               %  1
-define(EC_CORRUPT_MESSAGE,              'CorruptMessage').                 %  2
-define(EC_UNKNOWN_TOPIC_OR_PARTITION,   'UnknownTopicOrPartition').        %  3
-define(EC_INVALID_MESSAGE_SIZE,         'InvalidMessageSize').             %  4
-define(EC_LEADER_NOT_AVAILABLE,         'LeaderNotAvailable').             %  5
-define(EC_NOT_LEADER_FOR_PARTITION,     'NotLeaderForPartition').          %  6
-define(EC_REQUEST_TIMED_OUT,            'RequestTimedOut').                %  7
-define(EC_BROKER_NOT_AVAILABLE,         'BrokerNotAvailable').             %  8
-define(EC_REPLICA_NOT_AVAILABLE,        'ReplicaNotAvailable').            %  9
-define(EC_MESSAGE_TOO_LARGE,            'MessageTooLarge').                % 10
-define(EC_STALE_CONTROLLER_EPOCH,       'StaleControllerEpoch').           % 11
-define(EC_OFFSET_METADATA_TOO_LARGE,    'OffsetMetadataTooLarge').         % 12
-define(EC_NETWORK_EXCEPTION,            'NetworkException').               % 13
-define(EC_GROUP_LOAD_IN_PROGRESS,       'GroupLoadInProgress').            % 14
-define(EC_GROUP_COORDINATOR_NOT_AVAILABLE,
        'GroupCoordinatorNotAvailable').                                    % 15
-define(EC_NOT_COORDINATOR_FOR_GROUP,    'NotCoordinatorForGroup').         % 16
-define(EC_INVALID_TOPIC_EXCEPTION,      'InvalidTopicException').          % 17
-define(EC_MESSAGE_LIST_TOO_LARGE,       'MessageListTooLargeException').   % 18
-define(EC_NOT_ENOUGH_REPLICAS,          'NotEnoughReplicasException').     % 19
-define(EC_NOT_ENOUGH_REPLICAS_AFTER_APPEND,
        'NotEnoughReplicasAfterAppendException').                           % 20
-define(EC_INVALID_REQUIRED_ACKS,        'InvalidRequiredAcks').            % 21
-define(EC_ILLEGAL_GENERATION,           'IllegalGeneration').              % 22
-define(EC_INCONSISTENT_GROUP_PROTOCOL,  'InconsistentGroupProtocol').      % 23
-define(EC_INVALID_GROUP_ID,             'InvalidGroupId').                 % 24
-define(EC_UNKNOWN_MEMBER_ID,            'UnknownMemberId').                % 25
-define(EC_INVALID_SESSION_TIMEOUT,      'InvalidSessionTimeout').          % 26
-define(EC_REBALANCE_IN_PROGRESS,        'RebalanceInProgress').            % 27
-define(EC_INVALID_COMMIT_OFFSET_SIZE,   'InvalidCommitOffsetSize').        % 28
-define(EC_TOPIC_AUTHORIZATION_FAILED,   'TopicAuthorizationFailed').       % 29
-define(EC_GROUP_AUTHORIZATION_FAILED,   'GroupAuthorizationFailed').       % 30
-define(EC_CLUSTER_AUTHORIZATION_FAILED, 'ClusterAuthorizationFailed').     % 31
-define(EC_UNSUPPORTED_SASL_MECHANISM,   'UnsupportedSaslMechanism').       % 33
-define(EC_ILLEGAL_SASL_STATE,           'IllegalSaslState').               % 34
-define(EC_UNSUPPORTED_VERSION,          'UnsupportedVersion').             % 35
-define(EC_TOPIC_ALREADY_EXISTS,         'TopicExists').                    % 36
-define(EC_INVALID_PARTITIONS,           'InvalidPartitions').              % 37
-define(EC_INVALID_REPLICATION_FACTOR,   'InvalidReplicationFactor').       % 38
-define(EC_INVALID_REPLICA_ASSIGNMENT,   'InvalidReplicaAssignment').       % 39
-define(EC_INVALID_CONFIG,               'InvalidConfiguration').           % 40
-define(EC_NOT_CONTROLLER,               'NotController').                  % 41
-define(EC_INVALID_REQUEST,              'InvalidRequest').                 % 42
-define(EC_UNSUPPORTED_FOR_MESSAGE_FORMAT,
        'UnsupportedForMessageFormat').                                     % 43
-define(EC_POLICY_VIOLATION,             'PolicyViolation').                % 44

-endif.

