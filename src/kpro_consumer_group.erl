%%%
%%%   Copyright (c) 2014-2017, Klarna AB
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
%% data schema can be found here:
%% https://github.com/apache/kafka/blob/0.10.1/
%% core/src/main/scala/kafka/coordinator/GroupMetadataManager.scala

-module(kpro_consumer_group).

-export([decode/2]).

-export_type([decoded/0]).

-include("kpro.hrl").

-type tag() :: offset | group.
-type decoded() :: {tag(), Key::kpro:struct(), Value::kpro:struct()}.

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
%%       assignment (nullable)
%%           version          :: integer()
%%           topic_partitions :: [{Topic::binary(), [Partition::integer()]}]
%%           user_data        :: undefined | binary()
%% @end
-spec decode(binary(), ?kpro_null | binary()) -> decoded().
decode(KeyBin, ValueBin) ->
  {Tag, Key} = key(KeyBin),
  value(Tag, Key, ValueBin).

%%%_* Internal functions =======================================================

%% @private
-spec key(binary()) -> {tag(), kpro:struct()}.
key(<<V:16/integer, _/binary>> = Bin) when V =:= 0 orelse V =:=1 ->
  Schema = [ {version, int16}
           , {group_id, string}
           , {topic, string}
           , {partition, int32}
           ],
  {offset, dec(Schema, Bin)};
key(<<2:16/integer, _/binary>> = Bin) ->
  Schema = [ {version, int16}
           , {group_id, string}
           ],
  {group, dec(Schema, Bin)}.

%% @private
-spec value(tag(), kpro:struct(), binary()) -> decoded().
value(Tag, Key, V) when V =:= <<>> orelse V =:= ?kpro_null ->
  {Tag, Key, []};
value(offset, Key, <<0:16/integer, _/binary>> = Bin) ->
  Schema = [ {version, int16}
           , {offset, int64}
           , {metadata, string}
           , {timestamp, int64}
           ],
  {offset, Key, dec(Schema, Bin)};
value(offset, Key, <<1:16/integer, _/binary>> = Bin) ->
  Schema = [ {version, int16}
           , {offset, int64}
           , {metadata, string}
           , {commit_time, int64}
           , {expire_time, int64}
           ],
  {offset, Key, dec(Schema, Bin)};
value(group, Key, ValueBin) ->
  KeyVersion = kpro:find(version, Key),
  {group, Key, group(KeyVersion, ValueBin)}.

%% @private
-spec group(kpro:vsn(), binary()) -> kpro:struct() | no_return().
group(_KeyVersion = 2, <<ValueVersion:16/integer, _/binary>> = Bin) ->
  MemberMetaSchema = group_member_metadata_schema(ValueVersion),
  Schema = [ {version, int16}
           , {protocol_type, string}
           , {generation_id, int32}
           , {protocol, string}
           , {leader, string}
           , {members, {array, MemberMetaSchema}}
           ],
  dec(Schema, Bin).

%% @private
-spec group_member_metadata_schema(kpro:vsn()) -> kpro:schema().
group_member_metadata_schema(_Version = 0)->
  [ {member_id, string}
  , {client_id, string}
  , {client_host, string}
  , {session_timeout, int32}
  , {subscription, fun subscription/1}
  , {assignment, fun assignment/1}
  ];
group_member_metadata_schema(_Version = 1) ->
  [ {member_id, string}
  , {client_id, string}
  , {client_host, string}
  , {rebalance_timeout, int32}
  , {session_timeout, int32}
  , {subscription, fun subscription/1}
  , {assignment, fun assignment/1}
  ].

%% @private
nullable_bytes(Bin, BytesDecoder) ->
  case kpro_lib:decode(bytes, Bin) of
    {<<>>, Rest} ->
      {?kpro_null, Rest};
    {Bytes, Rest} ->
      {BytesDecoder(Bytes), Rest}
  end.

%% @private
subscription(Bytes) -> nullable_bytes(Bytes, fun decode_subscription/1).

%% @private
assignment(Bytes) -> nullable_bytes(Bytes, fun decode_assignment/1).

%% @private
decode_subscription(Bytes) ->
  Schema = kpro_lib:get_prelude_schema(cg_protocol_metadata, 0),
  dec(Schema, Bytes).

%% @private
decode_assignment(Bytes) ->
  Schema = kpro_lib:get_prelude_schema(cg_memeber_assignment, 0),
  dec(Schema, Bytes).

%% @private
dec(Schema, Bin) ->
  {R, <<>>} = kpro_rsp_lib:dec_struct(Schema, #{}, [], Bin),
  R.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
