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

%% This module tests below APIs
%% create_topics
%% delete_topics
%% delete_records
%% describe_configs
%% alter_configs
-module(kpro_topic_mngr_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro_private.hrl").

-define(RESOURCE_TYPE_TOPIC, 2).

%% Create a random-name partition with 1 partition 1 replica
%% Increase partition number to 2
create_topic_partition_test_() ->
  CreateTopicsVsn = get_max_api_vsn(create_topics),
  CreatePartitionsVsn = get_max_api_vsn(create_partitions),
  {timeout, 30,
   fun() ->
       test_create_topic_partition(CreateTopicsVsn, CreatePartitionsVsn)
   end}.

test_create_topic_partition(false, _) ->
  io:format(user, " skipped ", []);
test_create_topic_partition(CreateTopicsVsn, CreatePartitionsVsn) ->
  Topic = make_random_topic_name(),
  CreateTopicArgs =
    #{ name => Topic
     , num_partitions => 1
     , replication_factor => 1
     , assignments => []
     , configs => []
     },
  AssignNewPartitionsTo = [[ _BrokerId = 0 ]],
  CreatePartitionArgs =
    #{ topic => Topic
     , new_partitions => #{ count => 2
                          , assignment => AssignNewPartitionsTo
                          }
     },
  Timeout = timer:seconds(5),
  Opts = #{timeout => Timeout},
  kpro_test_lib:with_connection(
    fun(Endpoints, Config) -> kpro:connect_controller(Endpoints, Config) end,
    fun(Conn) ->
        TopicReq = kpro_req_lib:create_topics(CreateTopicsVsn,
                                              [CreateTopicArgs], Opts),
        {ok, TopicRsp} = kpro:request_sync(Conn, TopicReq, Timeout),
        ok = kpro_test_lib:parse_rsp(TopicRsp),
        case is_integer(CreatePartitionsVsn) of
          true ->
            PartitionReq =
              kpro_req_lib:create_partitions(CreatePartitionsVsn,
                                             [CreatePartitionArgs], Opts),
            {ok, PartitionRsp} = kpro:request_sync(Conn, PartitionReq, Timeout),
            ok = kpro_test_lib:parse_rsp(PartitionRsp);
          false ->
            ok
        end
    end).

%% Get all configurations for a topic.
describe_configs_test() ->
  Vsn = get_max_api_vsn(describe_configs),
  test_describe_configs(Vsn).

test_describe_configs(false) ->
  io:format(user, " skipped ", []);
test_describe_configs(Vsn) ->
  {ok, [Topic | _]} = get_test_topics(),
  DescribeConfigArgs =
    #{ resource_type => ?RESOURCE_TYPE_TOPIC
     , resource_name => Topic
     , config_names => ?null %% Get all configs
     },
  Opts = #{include_synonyms => false},
  Req = kpro_req_lib:describe_configs(Vsn, [DescribeConfigArgs], Opts),
  kpro_test_lib:with_connection(
    fun(Endpoints, Config) -> kpro:connect_controller(Endpoints, Config) end,
    fun(Conn) ->
        {ok, Rsp} = kpro:request_sync(Conn, Req, infinity),
        Resources = kpro_test_lib:parse_rsp(Rsp),
        ?assertMatch([#{ resource_name := Topic }], Resources)
    end).

%% Alter the configuration for a topic.
alter_configs_test() ->
  Vsn = get_max_api_vsn(alter_configs),
  test_alter_configs(Vsn).

test_alter_configs(false) ->
  io:format(user, " skipped ", []);
test_alter_configs(Vsn) ->
  {ok, [Topic | _]} = get_test_topics(),
  AlterConfigsArgs =
    fun(Policy) ->
        #{ resource_type => ?RESOURCE_TYPE_TOPIC
         , resource_name => Topic
         , config_entries => [#{config_name => "cleanup.policy",
                                config_value => Policy}]
         }
    end,
  Opts = #{validate_only => false},
  Req = fun(Policy) ->
            kpro_req_lib:alter_configs(Vsn, [AlterConfigsArgs(Policy)], Opts)
        end,
  DescribeVsn = get_max_api_vsn(describe_configs),
  GetPolicy = fun(Conn) ->
                  get_topic_config(DescribeVsn, Conn, Topic, "cleanup.policy")
              end,
  kpro_test_lib:with_connection(
    fun(Endpoints, Config) -> kpro:connect_controller(Endpoints, Config) end,
    fun(Conn) ->
        Before = GetPolicy(Conn),
        After = case Before of
                  <<"delete">> -> <<"compact">>;
                  <<"compact">> -> <<"delete">>
                end,
        {ok, Rsp} = kpro:request_sync(Conn, Req(After), infinity),
        ok = kpro_test_lib:parse_rsp(Rsp),
        ?assertEqual(After, GetPolicy(Conn))
    end).

%% Delete all topics created in this test module.
delete_topics_test() ->
  Timeout = case is_integer(get_max_api_vsn(create_partitions)) of
              true ->
                %% Kafka 1.0 or above
                5;
              false ->
                %% earlier than kafka 1.0
                20
            end,
  {timeout, Timeout,
   fun() ->
       Vsn = get_max_api_vsn(delete_topics),
       test_delete_topics(Vsn, timer:seconds(Timeout))
   end}.

test_delete_topics(false, _) ->
  io:format(user, " skipped ", []);
test_delete_topics(Vsn, Timeout) ->
  {ok, Topics} = get_test_topics(),
  Opts = #{timeout => Timeout},
  Req = kpro_req_lib:delete_topics(Vsn, Topics, Opts),
  kpro_test_lib:with_connection(
    fun(Endpoints, Config) -> kpro:connect_controller(Endpoints, Config) end,
    fun(Conn) ->
        {ok, Rsp} = kpro:request_sync(Conn, Req, infinity),
        ok = kpro_test_lib:parse_rsp(Rsp)
    end).

%%%_* Helpers ==================================================================

get_test_topics() ->
  kpro_test_lib:with_connection(fun get_test_topics/1).

get_test_topics(Connection) ->
  {ok, Versions} = kpro:get_api_versions(Connection),
  FL =
    [ fun() ->
          {_, Vsn} = maps:get(metadata, Versions),
          Req = kpro_req_lib:metadata(Vsn, all),
          kpro_connection:request_sync(Connection, Req, 5000)
      end
    , fun(#kpro_rsp{msg = Meta}) ->
          Topics = kpro:find(topics, Meta),
          Result =
            lists:foldl(
              fun(Topic, Acc) ->
                  ErrorCode = kpro:find(error_code, Topic),
                  ErrorCode = ?no_error, %% assert
                  Name = kpro:find(name, Topic),
                  case lists:prefix(atom_to_list(?MODULE),
                                    binary_to_list(Name)) of
                    true -> [Name | Acc];
                    false -> Acc
                  end
              end, [], Topics),
          {ok, Result}
      end
    ],
  kpro_lib:ok_pipe(FL).

make_random_topic_name() ->
  N = [atom_to_list(?MODULE), "-", integer_to_list(rand())],
  iolist_to_binary(N).

get_max_api_vsn(API) ->
  F = fun(Connection) -> kpro:get_api_versions(Connection) end,
  {ok, Versions} = kpro_test_lib:with_connection(F),
  {_, Max} = maps:get(API, Versions, {false, false}),
  Max.

rand() -> rand:uniform(1000000).

get_topic_config(false, _, _, _) ->
  false;
get_topic_config(Vsn, Conn, Topic, ConfigName) ->
  DescribeConfigArgs =
    #{ resource_type => ?RESOURCE_TYPE_TOPIC
     , resource_name => Topic
     , config_names => [ConfigName]
     },
  Req = kpro_req_lib:describe_configs(Vsn, [DescribeConfigArgs], #{}),
  {ok, Rsp} = kpro:request_sync(Conn, Req, infinity),
  [Resource] = kpro_test_lib:parse_rsp(Rsp),
  [Entry] = kpro:find(config_entries, Resource),
  kpro:find(config_value, Entry).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
