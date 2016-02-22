%% common header file for code generation and generated code.

-ifndef(kpro_common_hrl).
-define(kpro_common_hrl, true).

-ifndef(KAFKA_VERSION).
-define(KAFKA_VERSION, {0,9,0}). %% by default
-endif.

%% correlation IDs are 32 bit signed integers.
%% we use 27 bits only, and use the highest 5 bits to be redudant with API key
%% so that the decoder may decode the responses without the need of an extra
%% correlation ID to API key association.
-define(CORR_ID_BITS, 27).
-define(MAX_CORR_ID, 134217727).

%% kafka wire format primitive types

-type int8()       :: -128..127.
-type int16()      :: -32768..32767.
-type int32()      :: -2147483648..2147483647.
-type int64()      :: -9223372036854775808..9223372036854775807.
-type str()        :: undefined | string() | binary().
-type bytes()      :: undefined | binary().
-type api_key()    :: 0..16.
-type error_code() :: integer().

-define(is_kafka_primitive(T),
        (T =:= int8 orelse T =:= int16 orelse
         T =:= int32 orelse T =:= int64 orelse
         T =:= string orelse T =:= bytes)).

%% https://cwiki.apache.org/confluence/display/KAFKA/
%%       A+Guide+To+The+Kafka+Protocol#AGuideToTheKafkaProtocol-ApiKeys

-define(API_ProduceRequest,           0).
-define(API_FetchRequest,             1).
-define(API_OffsetRequest,            2).
-define(API_MetadataRequest,          3).
-define(API_OffsetCommitRequest,      8).
-define(API_OffsetFetchRequest,       9).
-define(API_GroupCoordinatorRequest, 10).
-define(API_JoinGroupRequest,        11).
-define(API_HeartbeatRequest,        12).
-define(API_LeaveGroupRequest,       13).
-define(API_SyncGroupRequest,        14).
-define(API_DescribeGroupsRequest,   15).
-define(API_ListGroupsRequest,       16).

-define(ALL_API_KEYS,
        [ ?API_ProduceRequest
        , ?API_FetchRequest
        , ?API_OffsetRequest
        , ?API_MetadataRequest
        , ?API_OffsetCommitRequest
        , ?API_OffsetFetchRequest
        , ?API_GroupCoordinatorRequest
        , ?API_JoinGroupRequest
        , ?API_HeartbeatRequest
        , ?API_LeaveGroupRequest
        , ?API_SyncGroupRequest
        , ?API_DescribeGroupsRequest
        , ?API_ListGroupsRequest
        ]).

-define(API_KEY_TO_REQ(ApiKey),
        case ApiKey of
          ?API_ProduceRequest          -> kpro_ProduceRequest;
          ?API_FetchRequest            -> kpro_FetchRequest;
          ?API_OffsetRequest           -> kpro_OffsetRequest;
          ?API_MetadataRequest         -> kpro_MetadataRequest;
          ?API_OffsetCommitRequest     -> [ kpro_OffsetCommitRequestV2
                                          , kpro_OffsetCommitRequestV1
                                          , kpro_OffsetCommitRequestV0
                                          ];
          ?API_OffsetFetchRequest      -> kpro_OffsetFetchRequest;
          ?API_GroupCoordinatorRequest -> kpro_GroupCoordinatorRequest;
          ?API_JoinGroupRequest        -> kpro_JoinGroupRequest;
          ?API_HeartbeatRequest        -> kpro_HeartbeatRequest;
          ?API_LeaveGroupRequest       -> kpro_LeaveGroupRequest;
          ?API_SyncGroupRequest        -> kpro_SyncGroupRequest;
          ?API_DescribeGroupsRequest   -> kpro_DescribeGroupsRequest;
          ?API_ListGroupsRequest       -> kpro_ListGroupsRequest
        end).

-define(API_KEY_TO_RSP(ApiKey),
        case ApiKey of
          ?API_ProduceRequest          -> kpro_ProduceResponse;
          ?API_FetchRequest            -> kpro_FetchResponse;
          ?API_OffsetRequest           -> kpro_OffsetResponse;
          ?API_MetadataRequest         -> kpro_MetadataResponse;
          ?API_OffsetCommitRequest     -> kpro_OffsetCommitResponse;
          ?API_OffsetFetchRequest      -> kpro_OffsetFetchResponse;
          ?API_GroupCoordinatorRequest -> kpro_GroupCoordinatorResponse;
          ?API_JoinGroupRequest        -> kpro_JoinGroupResponse;
          ?API_HeartbeatRequest        -> kpro_HeartbeatResponse;
          ?API_LeaveGroupRequest       -> kpro_LeaveGroupResponse;
          ?API_SyncGroupRequest        -> kpro_SyncGroupResponse;
          ?API_DescribeGroupsRequest   -> kpro_DescribeGroupsResponse;
          ?API_ListGroupsRequest       -> kpro_ListGroupsResponse
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

-endif.

