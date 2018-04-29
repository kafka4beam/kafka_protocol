%%%   Copyright (c) 2018, Klarna AB
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

%% A typical group member live-cycle:
%% 1. find_coordinator, to figure out which broker to connect to
%% 2. join_group, other members (if any) will have to re-join
%% 3. sync_group, leader assign partitions, members receive assignments
%% 4. heartbeat-cycle, to tell broker that it is still alive
%% 5. leave_group
full_flow_test() ->
  GroupId = make_group_id(full_flow_test),
  % find_coordinator (group)
  {ok, Connection} = connect_coordinator(GroupId),
  % join_group
  #{ member_id := MemberId
   , generation_id := Generation
   } = join_group(Connection, GroupId),
  ok = sync_group(Connection, GroupId, MemberId, Generation),
  % send hartbeats, there should be a generation_id in heartbeat requests,
  % generation bumps whenever there is a group re-balance, however since
  % we are testing with only one group member, we do not expect any group
  % rebalancing, hence generation_id should not change (alwyas send the same)
  F = fun() -> heartbeat(Connection, GroupId, MemberId, Generation) end,
  {HeartbeatPid, Mref} = erlang:spawn_monitor(F),
  ok = describe_groups(Connection, GroupId),
  ok = list_groups(Connection),
  HeartbeatPid ! stop,
  receive
    {'DOWN', Mref, process, HeartbeatPid, Reason} ->
      ?assertEqual(normal, Reason)
  end,
  ok = leave_group(Connection, GroupId, MemberId),
  ok = kpro:close_connection(Connection),
  ok.

%%%_* Helpers ==================================================================

connect_coordinator(GroupId) ->
  Cluster = kpro_test_lib:get_endpoints(plaintext),
  ConnCfg = kpro_test_lib:connection_config(plaintext),
  Args = #{type => group, id => GroupId},
  kpro:connect_coordinator(Cluster, ConnCfg, Args).

join_group(Connection, GroupId) ->
  Meta = #{ version => 0
          , topics => [?TOPIC]
          , user_data => <<"magic-1">>
          },
  Fields = #{ group_id => GroupId
            , session_timeout => timer:seconds(10)
            , rebalance_timeout => timer:seconds(10)
            , member_id => <<>>
            , protocol_type => <<"consumer">>
            , group_protocols =>
                [ #{ protocol_name => <<"test-v1">>
                   , protocol_metadata => Meta
                   }
                ]
            },
  Rsp = rand_vsn_request_sync(Connection, join_group, Fields),
  #{ error_code := no_error
   , group_protocol := <<"test-v1">>
   , leader_id := LeaderId
   , member_id := MemberId
   , members := [#{ member_id := MemberId1
                  , member_metadata := Meta
                  }]
   } = Rsp,
  %% only member in grou, leader must be self
  ?assertEqual(LeaderId, MemberId),
  ?assertEqual(MemberId, MemberId1),
  Rsp.

sync_group(Connection, GroupId, MemberId, Generation) ->
  MemberAssignment =
    #{ version => 0
     , topic_partitions => [#{ topic => ?TOPIC
                             , partitions => [0, 1, 2]
                             }]
     , user_data => <<"magic-1">>
     },
  Assignment =
    [ #{ member_id => MemberId
       , member_assignment => MemberAssignment
       }
    ],
  Fields = #{ group_id => GroupId
            , generation_id => Generation
            , member_id => MemberId
            , group_assignment => Assignment
            },
  Rsp = rand_vsn_request_sync(Connection, sync_group, Fields),
  #{ error_code := no_error
   , member_assignment := MemberAssignment
   } = Rsp,
  ok.

describe_groups(Connection, GroupId) ->
  Groups = [GroupId, <<"unknown-group">>],
  Body = #{group_ids => Groups},
  Rsp = rand_vsn_request_sync(Connection, describe_groups, Body),
  #{groups := RspGroups} = Rsp,
  lists:foreach(
    fun(#{error_code := ErrorCode}) ->
        ?assertEqual(no_error, ErrorCode)
    end, RspGroups).

list_groups(Connection) ->
  Rsp = rand_vsn_request_sync(Connection, list_groups, #{}),
  ?assertMatch(#{error_code := no_error}, Rsp),
  ok.

leave_group(Connection, GroupId, MemberId) ->
  Fields = #{ group_id => GroupId
            , member_id => MemberId
            },
  Rsp = rand_vsn_request_sync(Connection, leave_group, Fields),
  ?assertMatch(#{error_code := no_error}, Rsp),
  ok.

heartbeat(Connection, GroupId, MemberId, Generation) ->
  {ok, {Min, Max}} = kpro:get_api_vsn_range(Connection, heartbeat),
  SendFun =
    fun() ->
        Vsn = rand(Min, Max),
        Req = kpro:make_request(heartbeat, Vsn,
                                [ {group_id, GroupId}
                                , {generation_id, Generation}
                                , {member_id, MemberId}
                                ]),
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

rand_vsn_request_sync(Connection, API, Body) ->
  {ok, {Min, Max}} = kpro:get_api_vsn_range(Connection, API),
  Vsn = rand(Min, Max),
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

rand(Min, Max) ->
  rand() rem (Max - Min + 1) + Min.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
