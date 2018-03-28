%%%   Copyright (c) 2014-2018, Klarna AB
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

-module(kpro).

-export([ encode_request/3
        , make_request/3
        ]).

-export([ decode_batches/1
        , do_find/3
        , find/2
        , find/3
        ]).

-export([ request_sync/3
        , request_async/2
        ]).

-export([ connect_any/2
        , connect_partition_leader/5
        , query_api_versions/2
        ]).

-export_type([ batch_decode_result/0
             , batch_input/0
             , batch_meta/0
             , bytes/0
             , client_id/0
             , compress_option/0
             , corr_id/0
             , count/0
             , endpoint/0
             , error_code/0
             , field_name/0
             , field_value/0
             , headers/0
             , header_key/0
             , header_val/0
             , hostname/0
             , incomplete_batch/0
             , int8/0
             , int16/0
             , int32/0
             , int64/0
             , isolation_level/0
             , key/0
             , kv_list/0
             , magic/0
             , message/0
             , meta_input/0
             , msg_ts/0
             , offset/0
             , partition/0
             , portnum/0
             , primitive/0
             , primitive_type/0
             , producer_id/0
             , req/0
             , required_acks/0
             , rsp/0
             , schema/0
             , stack/0
             , str/0
             , struct/0
             , timestamp_type/0
             , topic/0
             , value/0
             , vsn/0
             , wait/0
             ]).

-include("kpro_private.hrl").

-type int8()       :: -128..127.
-type int16()      :: -32768..32767.
-type int32()      :: -2147483648..2147483647.
-type int64()      :: -9223372036854775808..9223372036854775807.
-type str()        :: ?null | string() | binary().
-type bytes()      :: ?null | binary().
-type error_code() :: int16() | atom().
-type msg_ts() :: int64().
-type producer_id() :: int64().
-type magic() :: int8().

-type client_id() :: binary().
-type hostname() :: binary() | string().
-type portnum() :: non_neg_integer().
-type endpoint() :: {hostname(), portnum()}.
-type corr_id() :: int32().
-type topic() :: binary().
-type partition() :: int32().
-type offset() :: int64().

-type header_key() :: binary().
-type header_val() :: binary().
-type headers() :: [{header_key(), header_val()}].
-type batch_meta_key() :: first_offset
                        | magic
                        | crc
                        | attributes
                        | last_offset_delta
                        | first_ts
                        | max_ts
                        | producer_id
                        | producer_epoch
                        | first_sequence.
% Attribute :: {compression, kpro:compress_option()}
%            | {ts_type, kpro:timestamp_type()}
%            | is_transaction | {is_transaction, boolean()}
%            | is_control | {is_control, boolean()}.
-type batch_attributes() :: proplists:proplist().
-type batch_meta_val() :: batch_attributes() | integer().

-type key() :: ?null | iodata().
-type value() :: ?null | iodata().
-type value_mabye_nested() :: value() | [{key(), kv_list()}].
-type kv_list() :: [kv() | tkv()].

-type msg_key() :: headers | ts | key | value.
-type msg_val() :: headers() | msg_ts() | key() | value().

-type kv() :: {key(), value_mabye_nested()}. % magic 0
-type tkv() :: {msg_ts(), key(), value_mabye_nested()}. % magic 1
-type msg_input() :: #{msg_key() => msg_val()}. % magic 2

-type meta_input() :: #{}.
-type batch_input() :: [kv()] % magic 0
                     | [tkv()] % magic 1
                     | [msg_input()]. % magic 2 non-transactional

-type incomplete_batch() :: ?incomplete_batch(int32()).
-type message() :: #kafka_message{}.
-type batch_meta() :: ?KPRO_NO_BATCH_META %% magic 0-1
                    | #{batch_meta_key() => batch_meta_val()}.
-type batch_decode_result() :: ?incomplete_batch(int32())
                             | {batch_meta(), [message()]}.

-type vsn() :: non_neg_integer().
-type count() :: non_neg_integer().
-type wait() :: non_neg_integer().
-type required_acks() :: -1..1.
-type primitive() :: integer() | string() | binary() | atom().
-type field_name() :: atom().
-type field_value() :: primitive() | struct() | [struct()].
-type struct() :: #{field_name() => field_value()}
                | [{field_name(), field_value()}].
-type api() :: atom().
-type req() :: #kpro_req{}.
-type rsp() :: #kpro_rsp{}.
-type compress_option() :: ?no_compression
                         | ?gzip
                         | ?snappy
                         | ?lz4.
-type timestamp_type() :: undefined | create | append.
-type primitive_type() :: boolean
                        | int8
                        | int16
                        | int32
                        | int64
                        | varint
                        | string
                        | nullable_string
                        | bytes
                        | records.
-type decode_fun() :: fun((binary()) -> {field_value(), binary()}).
-type struct_schema() :: [{field_name(), schema()}].
-type schema() :: primitive_type()
                | struct_schema()
                | {array, schema()}
                | decode_fun(). %% caller defined decoder
-type stack() :: [{api(), vsn()} | field_name()]. %% encode / decode stack
-type isolation_level() :: read_committed | read_uncommitted.
-type conn_config() :: kpro_connection:config().

%% All versions of kafka messages (records) share the same header:
%% Offset => int64
%% Length => int32
%% We need to at least fetch 12 bytes in order to fetch:
%%  - one complete message when it's magic v0-1 not compressed
%%  - one comprete batch when it's v0-1 compressed batch
%%    v0-1 compressed batch is embedded in a wrapper message (i.e. recursive)
%%  - one complete batch when it is v2.
%%    v2 batch is flat and trailing the batch header.
-define(BATCH_LEADING_BYTES, 12).

%%%_* APIs =====================================================================

%% @doc Help function to make a request. See also kpro_req_lib for more help
%% functions.
-spec make_request(api(), vsn(), struct()) -> req().
make_request(Api, Vsn, Fields) ->
  kpro_req_lib:make(Api, Vsn, Fields).

%% @doc Encode request to byte stream.
-spec encode_request(client_id(), corr_id(), req()) -> iodata().
encode_request(ClientId, CorrId, Req) ->
  kpro_req_lib:encode(ClientId, CorrId, Req).

%% @doc The messageset is not decoded upon receiving (in socket process).
%% Pass the message set as binary to the consumer process and decode there
%% Return `?incomplete_batch(ExpectedSize)' if the fetch size is not big
%% enough for even one single message. Otherwise return `{Meta, Messages}'
%% where `Meta' is either `?KPRO_NO_BATCH_META' for magic-version 0-1 or
%% `#kafka_batch_meta{}' for magic-version 2 or above.
-spec decode_batches(binary()) -> kpro:batch_decode_result().
decode_batches(<<_:64/?INT, L:32, T/binary>> = Bin) when size(T) >= L ->
  kpro_batch:decode(Bin);
decode_batches(<<_:64/?INT, L:32, _T/binary>>) ->
  %% not enough to decode one single message for magic v0-1
  %% or a single batch for magic v2
  ?incomplete_batch(L + ?BATCH_LEADING_BYTES);
decode_batches(_) ->
  %% not enough to even get the size header
  ?incomplete_batch(?BATCH_LEADING_BYTES).

%% @doc Send a request, wait for response.
%% Immediately return 'ok' if it is a produce request with `required_acks = 0'.
-spec request_sync(pid(), req(), timeout()) ->
        ok | {ok, rsp()} | {error, any()}.
request_sync(ConnectionPid, Request, Timeout) ->
  kpro_connection:request_sync(ConnectionPid, Request, Timeout).

%% @doc Send a request and get back a correlation ID to match future response.
%% Immediately return 'ok' if it is a produce request with `required_acks = 0'.
-spec request_async(pid(), req()) ->
        ok | {ok, corr_id()} | {error, any()}.
request_async(ConnectionPid, Request) ->
  kpro_connection:request_async(ConnectionPid, Request).

%% @doc Connect to any of the endpoints in the given list.
%% NOTE: Connection process is linked to caller unless `nolink => true'
%%       is set in connection config
-spec connect_any([endpoint()], conn_config()) ->
        {ok, kpro_connection:connection()} | {error, any()}.
connect_any(Endpoints, ConnConfig) ->
  kpro_connection_lib:connect_any(Endpoints, ConnConfig).

%% @doc Connect to partition leader.
%% It first tries to connect to any of the bootstraping nodes,
%% query metata to discover leader node, then connect to leader.
%% NOTE: Connection process is linked to caller unless `nolink => true'
%%       is set in connection connection config.
-spec connect_partition_leader([endpoint()], topic(), partition(),
                               conn_config(), timeout()) ->
        {ok, kpro_connection:connection()} | {error, any()}.
connect_partition_leader(BootstrapEndpoints, ConnConfig,
                         Topic, Partition, Timeout) ->
  kpro_connection_lib:connect_partition_leader(BootstrapEndpoints,
                                               ConnConfig,
                                               Topic, Partition,
                                               Timeout).

%% @doc Qury API versions using the given `kpro_connection' pid.
-spec query_api_versions(pid(), timeout()) ->
        {ok, #{api() => {Min :: vsn(), Max :: vsn()}}} | {error, any()}.
query_api_versions(Pid, Timeout) ->
  kpro_connection_lib:query_api_versions(Pid, Timeout).

%% @doc Find field value in a struct, raise an exception if not found.
-spec find(field_name(), struct()) -> field_value().
find(Field, Struct) ->
  do_find(Field, Struct, {no_such_field, Field}).

%% @doc Find field value in a struct, reutrn default if not found.
-spec find(field_name(), struct(), field_value()) -> field_value().
find(Field, Struct, Default) ->
  try
    find(Field, Struct)
  catch
    throw : {no_such_field, _} ->
      Default
  end.

%%%_* Internal functions =======================================================

do_find(Field, Struct, Throw) when is_map(Struct) ->
  try
    maps:get(Field, Struct)
  catch
    error : {badkey, _} ->
      erlang:throw(Throw)
  end;
do_find(Field, Struct, Throw) when is_list(Struct) ->
  case lists:keyfind(Field, 1, Struct) of
    {_, Value} -> Value;
    false -> erlang:throw(Throw)
  end;
do_find(_Field, Other, _Throw) ->
  erlang:throw({not_struct, Other}).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
