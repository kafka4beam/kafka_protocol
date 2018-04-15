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
-module(kpro_txn_lib).

-export([ add_partitions_to_txn/3
        , end_txn/3
        , init_txn_ctx/3
        ]).

-type txn_ctx() :: kpro:txn_ctx().
-type topic() :: kpro:topic().
-type partition() :: kpro:partition().

-define(DEFAULT_TIMEOUT, timer:seconds(5)).
-define(DEFAULT_TXN_TIMEOUT, timer:seconds(30)).

-include("kpro_private.hrl").

%% @see `kpro:init_txn_ctx/3'
init_txn_ctx(Connection, TxnId, Opts) ->
  ReqTimeout = maps:get(timeout, Opts, ?DEFAULT_TIMEOUT),
  TxnTimeout = maps:get(txn_timeout, Opts, ?DEFAULT_TXN_TIMEOUT),
  Req = kpro_req_lib:make(init_producer_id, _Vsn = 0,
                          #{ transactional_id => TxnId
                           , transaction_timeout_ms => TxnTimeout
                           }),
  FL =
    [ fun() -> kpro_connection:request_sync(Connection, Req, ReqTimeout) end
    , fun(#kpro_rsp{msg = Rsp}) -> make_txn_ctx(Connection, TxnId, Rsp) end
    ],
  kpro_lib:ok_pipe(FL).

%% @doc Commit or abort transaction.
-spec end_txn(txn_ctx(), commit | abort, #{timeout => timeout()}) ->
        ok | {error, any()}.
end_txn(TxnCtx, AbortOrCommit, Opts) ->
  Connection = maps:get(connection, TxnCtx),
  Timeout = maps:get(timeout, Opts, ?DEFAULT_TIMEOUT),
  Req = kpro_req_lib:end_txn(TxnCtx, AbortOrCommit),
  FL =
    [ fun() -> kpro_connection:request_sync(Connection, Req, Timeout) end
    , fun(#kpro_rsp{msg = #{error_code := ErrorCode}}) ->
          case kpro_error_code:is_error(ErrorCode) of
            true -> {error, ErrorCode};
            false -> ok
          end
      end
    ],
  kpro_lib:ok_pipe(FL).

%% @doc Add partitions to transaction.
-spec add_partitions_to_txn(txn_ctx(), [{topic(), partition()}],
                            #{timeout => timeout()}) -> ok | {error, any()}.
add_partitions_to_txn(TxnCtx, TPL, Opts) ->
  Connection = maps:get(connection, TxnCtx),
  Timeout = maps:get(timeout, Opts, ?DEFAULT_TIMEOUT),
  Req = kpro_req_lib:add_partitions_to_txn(TxnCtx, TPL),
  FL =
    [ fun() -> kpro_connection:request_sync(Connection, Req, Timeout) end
    , fun(#kpro_rsp{msg = Body}) -> parse_add_partitions_error(Body) end
    ],
  kpro_lib:ok_pipe(FL).

%%%_* Internals ================================================================

parse_add_partitions_error(#{errors := Errors0}) ->
  Errors =
  lists:flatten(
    lists:map(
      fun(#{topic := Topic, partition_errors := PartitionErrors}) ->
          lists:map(
            fun(#{partition := Partition, error_code := ErrorCode}) ->
                case kpro_error_code:is_error(ErrorCode) of
                  true -> {Topic, Partition, ErrorCode};
                  false -> []
                end
            end, PartitionErrors)
      end, Errors0)),
  case Errors =:= [] of
    true -> ok;
    _ -> {error, Errors}
  end.

make_txn_ctx(Connection, TxnId,
             #{ error_code := ?EC_NONE
              , producer_id := ProducerId
              , producer_epoch := ProducerEpoch
              }) ->
  {ok, #{ connection => Connection
        , transactional_id => TxnId
        , producer_id => ProducerId
        , producer_epoch => ProducerEpoch
        }};
make_txn_ctx(_Connection, _TxnId, #{error_code := EC}) ->
  {error, EC}.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
