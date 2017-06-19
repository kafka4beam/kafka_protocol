%%%   Copyright (c) 2017, Klarna AB
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
-module(kpro_prelude_schema).
-export([get/2]).

% # embedded in 'BYTES' content of
% # JoinGroupRequestV0.group_protocol.protocol_metadata
% # JoinGroupResponseV0.members.protocol_metadata
% ConsumerGroupProtocolMetadata => version [topics] user_data
%   version => INT16
%   topics => STRING
%   user_data => BYTES
get(cg_member_metadata, 0) ->
  get(cg_protocol_metadata, 0);
get(cg_protocol_metadata, 0) ->
  [{version, int16},
   {topics, {array, string}},
   {user_data, bytes}
  ];
% ## embedded in 'BYTES' content of
% ## SyncGroupRequestV0.group_assignment.member_assignment
% ConsumerGroupMemberAssignment => version [partition_assignments] user_data
%   version => INT16
%   partition_assignments => topic [partitions]
%     topic => STRING
%     partitions => INT32
%   user_data => BYTES
get(cg_memeber_assignment, 0) ->
  [{version, int16},
   {topic_partitions, {array, [{topic, string},
                               {partitions, {array, int32}}
                              ]}},
   {user_data, bytes}
  ].

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
