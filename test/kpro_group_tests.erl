%%%   Copyright (c) 2018-2020, Klarna AB
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

% This eunit module tests below APIs:
% offset_commit
% offset_fetch
% find_coordinator (group)
% join_group
% heartbeat
% leave_group
% sync_group
% describe_groups
% list_groups

-module(kpro_group_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro_private.hrl").

-define(TIMEOUT, 10000).
-define(TOPIC, <<"t1">>).
-define(STATIC_MEMBER_ID, <<"member-1">>).

%% A typical group member live-cycle:
%% 1. find_coordinator, to figure out which broker to connect to
%% 2. join_group, other members (if any) will have to re-join
%% 3. sync_group, leader assign partitions, members receive assignments
%% 4. heartbeat-cycle, to tell broker that it is still alive
%% 5. leave_group
full_flow_test_() ->
  [{atom_to_list(KafkaVsn),
    fun() -> test_full_flow(KafkaVsn) end }
   || KafkaVsn <- kafka_vsns()].

test_full_flow(KafkaVsn) ->
  GroupId = make_group_id(full_flow_test),
  StaticMemberID = ?STATIC_MEMBER_ID,
  % find_coordinator (group)
  {ok, Connection} = connect_coordinator(GroupId),
  % join_group
  #{ member_id := MemberId
   , generation_id := Generation
   } = join_group(Connection, GroupId, StaticMemberID, KafkaVsn),
  ok = sync_group(Connection, GroupId, MemberId, Generation,
                  StaticMemberID, KafkaVsn),
  % send hartbeats, there should be a generation_id in heartbeat requests,
  % generation bumps whenever there is a group re-balance, however since
  % we are testing with only one group member, we do not expect any group
  % rebalancing, hence generation_id should not change (alwyas send the same)
  F = fun() ->
          heartbeat(Connection, GroupId, MemberId, Generation, KafkaVsn)
      end,
  {HeartbeatPid, Mref} = erlang:spawn_monitor(F),
  ok = describe_groups(Connection, GroupId, KafkaVsn),
  ok = list_groups(Connection, KafkaVsn),
  HeartbeatPid ! stop,
  receive
    {'DOWN', Mref, process, HeartbeatPid, Reason} ->
      ?assertEqual(normal, Reason)
  end,
  ok = leave_group(Connection, GroupId, MemberId, KafkaVsn),
  ok = kpro:close_connection(Connection),
  ok.

%%%_* Helpers ==================================================================

connect_coordinator(GroupId) ->
  Cluster = kpro_test_lib:get_endpoints(plaintext),
  ConnCfg = kpro_test_lib:connection_config(plaintext),
  Args = #{type => group, id => GroupId},
  kpro:connect_coordinator(Cluster, ConnCfg, Args).

%% NOTE: MemberId is only relevant for join_group request version 4 or later.
join_group(Connection, GroupId, StaticMemberId, KafkaVsn) ->
  Meta = #{ version => 0
          , topics => [?TOPIC]
          , user_data => <<"magic-1">>
          },
  Send =
    fun(MemberId) ->
      Fields = #{ group_id => GroupId
                , session_timeout_ms => timer:seconds(10)
                , rebalance_timeout_ms => timer:seconds(10)
                , member_id => MemberId
                , protocol_type => <<"consumer">>
                , group_instance_id  => StaticMemberId
                , protocols =>
                    [ #{ name => <<"test-v1">>
                      , metadata => Meta
                      }
                    ]
                },
      request_sync(Connection, join_group, Fields, KafkaVsn)
    end,
  #{ error_code := ErrorCode
   , member_id := MyMemberId
   } = Rsp0 = Send(<<>>),
  Rsp =
    case ErrorCode of
      no_error ->
        Rsp0;
      member_id_required ->
        %% https://cwiki.apache.org/confluence/display/KAFKA/KIP-394
        %% Since kafka 2.2, members will maybe receive old member ID
        %% with a member_id_required error code
        Send(MyMemberId)
    end,
  #{ error_code := no_error
   , protocol_name := <<"test-v1">>
   , leader := LeaderId
   , member_id := MyMemberId
   , members := [#{ member_id := MemberId
                  , metadata := Meta
                  }]
   } = Rsp,
  %% only member in grou, leader must be self
  ?assertEqual(LeaderId, MyMemberId),
  ?assertEqual(MyMemberId, MemberId),
  Rsp.

sync_group(Connection, GroupId, MemberId, Generation,
           StaticMemberId, KafkaVsn) ->
  MemberAssignment =
    #{ version => 0
     , topic_partitions => [#{ topic => ?TOPIC
                             , partitions => [0, 1, 2]
                             }]
     , user_data => <<"magic-1">>
     },
  Assignment =
    [ #{ member_id => MemberId
       , assignment => MemberAssignment
       }
    ],
  Fields = #{ group_id => GroupId
            , generation_id => Generation
            , member_id => MemberId
            , assignments => Assignment
            , group_instance_id => StaticMemberId
            },
  Rsp = request_sync(Connection, sync_group, Fields, KafkaVsn),
  #{ error_code := no_error
   , assignment := MemberAssignment
   } = Rsp,
  ok.

describe_groups(Connection, GroupId, KafkaVsn) ->
  Groups = [GroupId, <<"unknown-group">>],
  Body = #{groups => Groups, include_authorized_operations => true},
  Rsp = request_sync(Connection, describe_groups, Body, KafkaVsn),
  #{groups := RspGroups} = Rsp,
  lists:foreach(
    fun(#{error_code := ErrorCode}) ->
        ?assertEqual(no_error, ErrorCode)
    end, RspGroups).

list_groups(Connection, KafkaVsn) ->
  Rsp = request_sync(Connection, list_groups, #{}, KafkaVsn),
  ?assertMatch(#{error_code := no_error}, Rsp),
  ok.

leave_group(Connection, GroupId, MemberId, KafkaVsn) ->
  Fields = #{ group_id => GroupId
            , member_id => MemberId
              %% members field since 2.3
            , members => [#{member_id => MemberId,
                            group_instance_id => ?STATIC_MEMBER_ID
                           }]
            },
  Rsp = request_sync(Connection, leave_group, Fields, KafkaVsn),
  ?assertMatch(#{error_code := no_error}, Rsp),
  ok.

heartbeat(Connection, GroupId, MemberId, Generation, KafkaVsn) ->
  Vsn = maps:get(heartbeat, max_vsn(KafkaVsn)),
  Req = kpro:make_request(heartbeat, Vsn,
                          [ {group_id, GroupId}
                          , {generation_id, Generation}
                          , {member_id, MemberId}
                          , {group_instance_id, ?STATIC_MEMBER_ID}
                          ]),
  SendFun =
    fun() ->
        {ok, #kpro_rsp{msg = Rsp}} =
          kpro:request_sync(Connection, Req, ?TIMEOUT),
        ErrorCode = kpro:find(error_code, Rsp),
        ?assertEqual(no_error, ErrorCode)
    end,
  heartbeat_loop(SendFun).

heartbeat_loop(SendFun) ->
  ok = SendFun(),
  receive
    stop ->
      exit(normal)
  after
    100 ->
      heartbeat_loop(SendFun)
  end.

request_sync(Connection, API, Body, KafkaVsn) ->
  Vsn = maps:get(API, max_vsn(KafkaVsn)),
  Req = kpro:make_request(API, Vsn, Body),
  {ok, #kpro_rsp{msg = Rsp}} = kpro:request_sync(Connection, Req, ?TIMEOUT),
  Rsp.

str(Atom) -> atom_to_list(Atom).

bin(I) when is_integer(I) -> integer_to_binary(I);
bin(Str) -> iolist_to_binary(Str).

%% Make a random group ID, so test cases would not interfere each other.
make_group_id(Case) ->
  bin([str(?MODULE), "-", str(Case), "-", bin(rand()), "-cg"]).

rand() ->
  {_, _, I} = os:timestamp(),
  I.

kafka_vsns() ->
  case os:getenv("KAFKA_VERSION") of
    "0.9"  -> [v0_9];
    "0.10" -> [v0_9, v0_10];
    "0.11" -> [v0_9, v0_10, v0_11];
    "1.1"  -> [v0_9, v0_10, v0_11, v1_0];
    _      -> [v0_9, v0_10, v0_11, v1_0, v2_0, v2_1, v2_2, v2_3, v2_4]
  end.

max_vsn(v0_9) -> max_vsn(v0_10);
max_vsn(v0_10) ->
  #{ join_group => 0
   , heartbeat => 0
   , leave_group => 0
   , sync_group => 0
   , describe_groups => 0
   , list_groups => 0
   };
max_vsn(v0_11) -> max_vsn(v1_0);
max_vsn(v1_0) -> max_vsn(v1_1);
max_vsn(v1_1) ->
  #{ join_group => 2
   , heartbeat => 1
   , leave_group => 1
   , sync_group => 1
   , describe_groups => 1
   , list_groups => 1
   };
max_vsn(v2_0) -> max_vsn(v2_1);
max_vsn(v2_1) ->
  #{ join_group => 3
   , heartbeat => 2
   , leave_group => 2
   , sync_group => 2
   , describe_groups => 2
   , list_groups => 2
   };
max_vsn(v2_2) ->
  #{ join_group => 4
   , heartbeat => 2
   , leave_group => 2
   , sync_group => 2
   , describe_groups => 2
   , list_groups => 2
   };
max_vsn(v2_3) ->
  #{ join_group => 5
   , heartbeat => 3
   , leave_group => 2
   , sync_group => 3
   , describe_groups => 3
   , list_groups => 2
   };
max_vsn(v2_4) ->
  #{ join_group => 6
   , heartbeat => 4
   , leave_group => 4
   , sync_group => 4
   , describe_groups => 5
   , list_groups => 3
   }.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
