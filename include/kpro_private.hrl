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

-define(IS_STRUCT(S), (is_list(S) orelse is_map(S))).

-define(MIN_MAGIC_2_PRODUCE_API_VSN, 3). %% since kafka 0.11
-define(MIN_MAGIC_2_FETCH_API_VSN, 4). %% since kafka 0.11
-define(MIN_INCREMENTAL_FETCH_API_VSN, 7). %% since kafka 1.1.0

%% SASL auth mechanisms
-define(plain, plain).
-define(scram_sha_256, scram_sha_256).
-define(scram_sha_512, scram_sha_512).
-define(IS_SCRAM(Mechanism), (Mechanism =:= ?scram_sha_256 orelse
                              Mechanism =:= ?scram_sha_512)).
-define(IS_PLAIN_OR_SCRAM(Mechanism), (Mechanism =:= ?plain orelse
                                       ?IS_SCRAM(Mechanism))).

-define(KAFKA_0_9,   9).
-define(KAFKA_0_10, 10).
-define(KAFKA_0_11, 11).
-define(KAFKA_1_0, 100).
-define(KAFKA_1_1, 110).

-ifdef(OTP_RELEASE).
-define(BIND_STACKTRACE(Var), :Var).
-define(GET_STACKTRACE(Var), ok).
-else.
-define(BIND_STACKTRACE(Var),).
-define(GET_STACKTRACE(Var), Var = erlang:get_stacktrace()).
-endif.

-endif.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
