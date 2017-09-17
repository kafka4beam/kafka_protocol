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

%% Internal use only

-ifndef(KPRO_PRIVATE_HRL).
-define(KPRO_PRIVATE_HRL, true).

-include("kpro.hrl").

%% Compression attributes
-define(KPRO_COMPRESS_NONE,   0).
-define(KPRO_COMPRESS_GZIP,   1).
-define(KPRO_COMPRESS_SNAPPY, 2).
-define(KPRO_COMPRESS_LZ4,    3).

-define(KPRO_COMPRESSION_MASK, 2#111).
-define(KPRO_IS_GZIP_ATTR(ATTR),
        ((?KPRO_COMPRESSION_MASK band ATTR) =:= ?KPRO_COMPRESS_GZIP)).
-define(KPRO_IS_SNAPPY_ATTR(ATTR),
        ((?KPRO_COMPRESSION_MASK band ATTR) =:= ?KPRO_COMPRESS_SNAPPY)).
-define(KPRO_IS_LZ4_ATTR(ATTR),
        ((?KPRO_COMPRESSION_MASK band ATTR) =:= ?KPRO_COMPRESS_LZ4)).

-define(KPRO_TS_TYPE_MASK, 2#1000).
-define(KPRO_IS_CREATE_TS(ATTR), ((?KPRO_TS_TYPE_MASK band ATTR) =:= 0)).
-define(KPRO_IS_APPEND_TS(ATTR), ((?KPRO_TS_TYPE_MASK band ATTR) =/= 0)).

%% some pre-defined default values
-define(KPRO_REPLICA_ID, -1).
-define(KPRO_API_VERSION, 0).
-define(KPRO_MAGIC_0, 0).
-define(KPRO_MAGIC_1, 1).
-define(KPRO_ATTRIBUTES, ?KPRO_COMPRESS_NONE).

%% correlation IDs are 32 bit signed integers.
%% we use 24 bits only, and use the highest 5 bits to be redudant with API key
%% and next 3 bits with API version
%% so that the decoder may decode the responses without the need of an extra
%% correlation ID to API key association.
-define(API_KEY_BITS, 5).
-define(API_VERSION_BITS, 3).
-define(CORR_ID_BITS, (32 - (?API_KEY_BITS + ?API_VERSION_BITS))).
-define(MAX_CORR_ID, ((1 bsl ?CORR_ID_BITS) - 1)).

-define(IS_KAFKA_PRIMITIVE(T),
        (T =:= boolean orelse T =:= int8 orelse T =:= int16 orelse
         T =:= int32 orelse T =:= int64 orelse
         T =:= string orelse T =:= nullable_string orelse
         T =:= bytes orelse T =:= records)).

-define(API_KEY_TO_REQ(ApiKey),
        case ApiKey of
           0 -> produce_request;
           1 -> fetch_request;
           2 -> offsets_request;
           3 -> metadata_request;
           4 -> leader_and_isr_request;
           5 -> stop_replica_request;
           6 -> update_metadata_request;
           7 -> controlled_shutdown_request;
           8 -> offset_commit_request;
           9 -> offset_fetch_request;
          10 -> group_coordinator_request;
          11 -> join_group_request;
          12 -> heartbeat_request;
          13 -> leave_group_request;
          14 -> sync_group_request;
          15 -> describe_groups_request;
          16 -> list_groups_request;
          17 -> sasl_handshake_request;
          18 -> api_versions_request;
          19 -> create_topics_request;
          20 -> delete_topics_request;
          N  -> N %% unknown api key
        end).

-define(REQ_TO_API_KEY(Req),
        case Req of
          produce_request             ->  0;
          fetch_request               ->  1;
          offsets_request             ->  2;
          metadata_request            ->  3;
          leader_and_isr_request      ->  4;
          stop_replica_request        ->  5;
          update_metadata_request     ->  6;
          controlled_shutdown_request ->  7;
          offset_commit_request       ->  8;
          offset_fetch_request        ->  9;
          group_coordinator_request   -> 10;
          join_group_request          -> 11;
          heartbeat_request           -> 12;
          leave_group_request         -> 13;
          sync_group_request          -> 14;
          describe_groups_request     -> 15;
          list_groups_request         -> 16;
          sasl_handshake_request      -> 17;
          api_versions_request        -> 18;
          create_topics_request       -> 19;
          delete_topics_request       -> 20
        end).

-define(API_KEY_TO_RSP(ApiKey),
        case ApiKey of
           0 -> produce_response;
           1 -> fetch_response;
           2 -> offsets_response;
           3 -> metadata_response;
           4 -> leader_and_isr_response;
           5 -> stop_replica_response;
           6 -> update_metadata_response;
           7 -> controlled_shutdown_response;
           8 -> offset_commit_response;
           9 -> offset_fetch_response;
          10 -> group_coordinator_response;
          11 -> join_group_response;
          12 -> heartbeat_response;
          13 -> leave_group_response;
          14 -> sync_group_response;
          15 -> describe_groups_response;
          16 -> list_groups_response;
          17 -> sasl_handshake_response;
          18 -> api_versions_response;
          19 -> create_topics_response;
          20 -> delete_topics_response
        end).

-define(null, ?kpro_null).

-endif.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
