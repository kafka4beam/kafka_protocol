%%%
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

%% This module decodes messages in __consumer_offsets topic
-module(kpro_consumer_group).

-export([ decode/2
        , decode/3
        ]).

-export_type([decoded/0]).

-include("kpro.hrl").

-type tag() :: offset | group.
-type decoded_kv() :: [{atom(), term()}].
-type decoded() :: {tag(), Key::decoded_kv(), Value::decoded_kv()}.

%%%_* APIs =====================================================================

%% @doc This function takes key and value binaries of a kafka message consumed
%% from __consumer_offsets topic, and return decoded values with a tag.
%% spec: {Tag :: offset | group, DecodedKey, DecodedValue}
%%
%% NOTE! DecodedValue can be an empty list
%%       (when consumer group is dead or after offset is expired).
%%
%% Key Fields when version = 0 | 1 (committed offset)
%%   version   :: 0 | 1
%%   group_id  :: binary()
%%   topic     :: binary()
%%   partition :: integer()
%%
%% Key Fields when version = 2 (consumer group metadata)
%%   version  :: 2
%%   group_id :: binary()
%%
%% Value Fields (when key version is 0 | 1):
%%   version     :: 0 | 1
%%   offset      :: integer()
%%   metdata     :: binary()
%%   timestamp   :: integer() when version = 0
%%   commit_time :: integer() when version = 1
%%   expire_time :: integer() when version = 1
%%
%% Value Fields (when key version is 2):
%%   version       :: integer() %% up to the consuemr implementation
%%   protocol_type :: binary()  %% should be `<<"consumer">>' but not must
%%   generation_id :: integer()
%%   protocol      :: binary()  %% `<<"roundrobin">>' etc.
%%   leader        :: binary()
%%   members       :: array of
%%       member_id       :: binary()
%%       client_id       :: binary()
%%       client_host     :: binary()
%%       session_timeout :: integer() %% milliseconds
%%       subscription ::
%%           version    :: integer()
%%           topics     :: [binary()]
%%           user_data  :: binary()
%%   assignment
%%       version          :: integer()
%%       topic_partitions :: [{Topic::binary(), [Partition::integer()]}]
%%       user_data        :: undefined | binary()
%% @end

%% @equiv decode(false, KeyBin, ValueBin)
decode(KeyBin, ValueBin) ->
  decode(false, KeyBin, ValueBin).

-spec decode(boolean(), binary(), undefined | binary()) -> decoded().
decode(UseMaps, KeyBin, ValueBin) ->
  {Tag, Key} = key(UseMaps, KeyBin),
  value(UseMaps, Tag, Key, ValueBin).

%%%_* Internal functions =======================================================

-spec key(boolean(), binary()) -> {tag(), decoded_kv()}.
key(UseMaps, <<V:16/integer, _/binary>> = Bin) when V =:= 0 orelse V =:=1 ->
  Schema = [ {version, int16}
           , {group_id, string}
           , {topic, string}
           , {partition, int32}
           ],
  {offset, dec(UseMaps, Schema, Bin)};
key(UseMaps, <<2:16/integer, _/binary>> = Bin) ->
  Schema = [ {version, int16}
           , {group_id, string}
           ],
  {group, dec(UseMaps, Schema, Bin)}.


-spec value(boolean(), tag(), decoded_kv(), binary()) -> decoded().
value(false = _UseMaps, Tag, Key, V) when V =:= <<>> orelse V =:= undefined ->
  {Tag, Key, []};
value(true = _UseMaps, Tag, Key, V) when V =:= <<>> orelse V =:= undefined ->
  {Tag, Key, #{}};
value(UseMaps, offset, Key, <<0:16/integer, _/binary>> = Bin) ->
  Schema = [ {version, int16}
           , {offset, int64}
           , {metadata, string}
           , {timestamp, int64}
           ],
  {offset, Key, dec(UseMaps, Schema, Bin)};
value(UseMaps, offset, Key, <<1:16/integer, _/binary>> = Bin) ->
  Schema = [ {version, int16}
           , {offset, int64}
           , {metadata, string}
           , {commit_time, int64}
           , {expire_time, int64}
           ],
  {offset, Key, dec(UseMaps, Schema, Bin)};
value(false = UseMaps, group, Key, ValueBin) ->
  {version, Version} = lists:keyfind(version, 1, Key),
  {group, Key, group(UseMaps, Version, ValueBin)};
value(true = UseMaps,group, Key, ValueBin) ->
  Version = maps:get(version, Key),
  {group, Key, group(UseMaps, Version, ValueBin)}.

group(UseMaps, 2, Bin) ->
  Schema = [ {version, int16}
           , {protocol_type, string}
           , {generation_id, int32}
           , {protocol, string}
           , {leader, string}
           , {members, {array, fun group_member/2}}
           ],
  dec(UseMaps, Schema, Bin).

group_member(UseMaps, Bin) ->
  Schema = [ {member_id, string}
           , {client_id, string}
           , {client_host, string}
           , {session_timeout, int32}
           , {subscription, fun subscription/2}
           , {assignment, fun assignment/2}
           ],
  do_dec(UseMaps, Schema, Bin).

subscription(UseMaps, Bin) ->
  {Bytes, Rest} = kpro:decode(false, bytes, Bin),
  {M, <<>>} = kpro:decode(false, kpro_ConsumerGroupProtocolMetadata, Bytes),
  #kpro_ConsumerGroupProtocolMetadata{ version = Version
                                     , topicName_L = Topics
                                     , userData = UserData
                                     } = M,
  Fields =
    case UseMaps of
      false ->
        [{version, Version}, {topics, Topics}, {user_data, UserData}];
      true ->
        #{version => Version, topics => Topics, user_data => UserData}
    end,
  {Fields, Rest}.

assignment(UseMaps, Bin) ->
  {Bytes, Rest} = kpro:decode(false, bytes, Bin),
  {Assignment, <<>>} = kpro:decode(false, kpro_ConsumerGroupMemberAssignment, Bytes),
  #kpro_ConsumerGroupMemberAssignment{ version = Version
                                     , consumerGroupPartitionAssignment_L = PL
                                     , userData = UserData
                                     } = Assignment,
  Fields =
    case UseMaps of
      false ->
        F = fun(#kpro_ConsumerGroupPartitionAssignment{ topicName = Topic
                                                      , partition_L = Partitions
                                                      }, Acc) ->
                [{Topic, Partitions} | Acc]
            end,
        TPs = lists:foldl(F, [], PL),
        [{version, Version}, {topic_partitions, TPs}, {user_data, UserData}];
      true ->
        F = fun(#kpro_ConsumerGroupPartitionAssignment{ topicName = Topic
                                                      , partition_L = Partitions
                                                      }, Acc) ->
                maps:put(Topic, Partitions, Acc)
            end,
        TPs = lists:foldl(F, #{}, PL),
        #{version => Version, topic_partitions => TPs, user_data => UserData}
    end,
  {Fields, Rest}.

dec(UseMaps, Schema, Bin) ->
  {Acc, <<>>} = do_dec(UseMaps, Schema, Bin),
  Acc.

do_dec(false = _UseMaps, Schema, Bin) -> do_dec(false, Schema, Bin, []);
do_dec(true = _UseMaps, Schema, Bin) -> do_dec(true, Schema, Bin, #{}).

do_dec(false = _UseMaps, [], Rest, Acc) -> {lists:reverse(Acc), Rest};
do_dec(true = _UseMaps, [], Rest, Acc) -> {Acc, Rest};
do_dec(false = UseMaps, [{FieldName, Type} | Schema], Bin, Acc) when is_binary(Bin) ->
  {Value, Rest} = kpro:decode(UseMaps, Type, Bin),
  do_dec(UseMaps, Schema, Rest, [{FieldName, Value} | Acc]);
do_dec(true = UseMaps, [{FieldName, Type} | Schema], Bin, Acc) when is_binary(Bin) ->
  {Value, Rest} = kpro:decode(UseMaps, Type, Bin),
  do_dec(UseMaps, Schema, Rest, maps:put(FieldName, Value, Acc)).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
