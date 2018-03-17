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

-define(no_compression, no_compression).
-define(gzip, gzip).
-define(snappy, snappy).
-define(lz4, lz4).

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

-define(KPRO_TS_TYPE_CREATE, 0).
-define(KPRO_TS_TYPE_APPEND, 2#1000).

-define(KPRO_TS_TYPE_MASK, 2#1000).
-define(KPRO_IS_CREATE_TS(ATTR), ((?KPRO_TS_TYPE_MASK band ATTR) =:= 0)).
-define(KPRO_IS_APPEND_TS(ATTR), ((?KPRO_TS_TYPE_MASK band ATTR) =/= 0)).

%% some pre-defined default values
-define(KPRO_REPLICA_ID, -1).
-define(KPRO_API_VERSION, 0).
-define(KPRO_MAGIC_0, 0).
-define(KPRO_MAGIC_1, 1).

-define(IS_KAFKA_PRIMITIVE(T),
        (T =:= boolean orelse T =:= int8 orelse T =:= int16 orelse
         T =:= int32 orelse T =:= int64 orelse
         T =:= string orelse T =:= nullable_string orelse
         T =:= bytes orelse T =:= records)).

-define(API_KEY_ATOM(ApiKey),
        case ApiKey of
           0 -> produce;
           1 -> fetch;
           2 -> list_offsets;
           3 -> metadata;
           4 -> leader_and_isr;
           5 -> stop_replica;
           6 -> update_metadata;
           7 -> controlled_shutdown;
           8 -> offset_commit;
           9 -> offset_fetch;
          10 -> group_coordinator;
          11 -> join_group;
          12 -> heartbeat;
          13 -> leave_group;
          14 -> sync_group;
          15 -> describe_groups;
          16 -> list_groups;
          17 -> sasl_handshake;
          18 -> api_versions;
          19 -> create_topics;
          20 -> delete_topics;
          21 -> delete_records;
          22 -> init_producer_id;
          23 -> offset_for_leader_epoch;
          24 -> add_partitions_to_txn;
          25 -> add_offsets_to_txn;
          26 -> end_txn;
          27 -> write_txn_markers;
          28 -> txn_offset_commit;
          29 -> describe_acls;
          30 -> create_acls;
          31 -> delete_acls;
          32 -> describe_configs;
          33 -> alter_configs;
          34 -> alter_replica_log_dirs;
          35 -> describe_log_dirs;
          36 -> sasl_authenticate;
          37 -> create_partitions
        end).

-define(API_KEY_INTEGER(Req),
        case Req of
          produce                 ->  0;
          fetch                   ->  1;
          list_offsets            ->  2;
          metadata                ->  3;
          leader_and_isr          ->  4;
          stop_replica            ->  5;
          update_metadata         ->  6;
          controlled_shutdown     ->  7;
          offset_commit           ->  8;
          offset_fetch            ->  9;
          group_coordinator       -> 10;
          join_group              -> 11;
          heartbeat               -> 12;
          leave_group             -> 13;
          sync_group              -> 14;
          describe_groups         -> 15;
          list_groups             -> 16;
          sasl_handshake          -> 17;
          api_versions            -> 18;
          create_topics           -> 19;
          delete_topics           -> 20;
          delete_records          -> 21;
          init_producer_id        -> 22;
          offset_for_leader_epoch -> 23;
          add_partitions_to_txn   -> 24;
          add_offsets_to_txn      -> 25;
          end_txn                 -> 26;
          write_txn_markers       -> 27;
          txn_offset_commit       -> 28;
          describe_acls           -> 29;
          create_acls             -> 30;
          delete_acls             -> 31;
          describe_configs        -> 32;
          alter_configs           -> 33;
          alter_replica_log_dirs  -> 34;
          describe_log_dirs       -> 35;
          sasl_authenticate       -> 36;
          create_partitions       -> 37
        end).

-define(null, ?kpro_null).

-define(INT, signed-integer).

-define(ISOLATION_LEVEL_ATOM(I),
        case I of
          0 -> ?kpro_read_uncommitted;
          1 -> ?kpro_read_committed
        end).

-define(ISOLATION_LEVEL_INTEGER(I),
        case I of
          ?kpro_read_uncommitted -> 0;
          ?kpro_read_committed   -> 1
        end).


-define(SCHEMA_MODULE, kpro_schema).

-define(PRELUDE, kpro_prelude_schema).

-define(IS_STRUCT(S), (is_list(S) orelse is_map(S))).

-endif.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
