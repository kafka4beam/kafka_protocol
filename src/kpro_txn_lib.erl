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

-export([ add_offsets_to_txn/3
        , add_partitions_to_txn/3
        , end_txn/3
        , txn_init_ctx/3
        , txn_offset_commit/5
        ]).

-type txn_ctx() :: kpro:txn_ctx().
-type topic() :: kpro:topic().
-type partition() :: kpro:partition().
-type offsets_to_commit() :: kpro:offsets_to_commit().
-type group_id() :: kpro:group_id().
-type connection() :: kpro:connection().

-define(DEFAULT_TIMEOUT, timer:seconds(5)).
-define(DEFAULT_TXN_TIMEOUT, timer:seconds(30)).

-include("kpro_private.hrl").

%% @see kpro:txn_init_ctx/3.
txn_init_ctx(Connection, TxnId, Opts) ->
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
    , fun(#kpro_rsp{msg = #{error_code := EC}}) -> ok_or_error_tuple(EC) end
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
    , fun(#kpro_rsp{msg = Body}) -> parse_add_partitions_rsp(Body) end
    ],
  kpro_lib:ok_pipe(FL).

%% @doc Send consumer group ID to transaction coordinator.
%% Transaction coordinator will map the group ID to its internal
%% partition number in __consumer_offsets topic.
%% then add that topic-partition to transaction like what the
%% `add_partitions_to_txn' API would achieve.
-spec add_offsets_to_txn(txn_ctx(), group_id(),
                         #{timeout => timeout()}) -> ok | {error, any()}.
add_offsets_to_txn(TxnCtx, CgId, Opts) ->
  Connection = maps:get(connection, TxnCtx),
  Timeout = maps:get(timeout, Opts, ?DEFAULT_TIMEOUT),
  Req = kpro_req_lib:add_offsets_to_txn(TxnCtx, CgId),
  FL =
    [ fun() -> kpro_connection:request_sync(Connection, Req, Timeout) end
    , fun(#kpro_rsp{msg = #{error_code := EC}}) -> ok_or_error_tuple(EC) end
    ],
  kpro_lib:ok_pipe(FL).

-spec txn_offset_commit(connection(), group_id(), txn_ctx(),
                        offsets_to_commit(),
                        #{timeout => timeout(),
                          user_data => binary()}) -> ok | {error, any()}.
txn_offset_commit(GrpConnection, GrpId, TxnCtx, Offsets, Opts) ->
  Timeout = maps:get(timeout, Opts, ?DEFAULT_TIMEOUT),
  UserData = maps:get(user_data, Opts, <<>>),
  Req = kpro_req_lib:txn_offset_commit(GrpId, TxnCtx, Offsets, UserData),
  FL =
    [ fun() -> kpro_connection:request_sync(GrpConnection, Req, Timeout) end
    , fun(#kpro_rsp{msg = Body}) -> parse_txn_offset_commit_rsp(Body) end
    ],
  kpro_lib:ok_pipe(FL).

%%%_* Internals ================================================================

parse_txn_offset_commit_rsp(#{topics := Topics}) ->
  FP = fun(#{ partition := Partition
            , error_code := EC
            }, Acc) ->
           case ?no_error =:= EC of
             true  -> Acc;
             false -> [{Partition, EC} | Acc]
           end
       end,
  FT = fun(#{ topic := Topic
            , partitions := Partitions
            }, Acc) ->
           PartitionErrs = lists:foldl(FP, [], Partitions),
           [{{Topic, Partition}, EC} || {Partition, EC} <- PartitionErrs] ++ Acc
       end,
  case lists:foldl(FT, [], Topics) of
    [] -> ok;
    Errors -> {error, Errors}
  end.

parse_add_partitions_rsp(#{errors := Errors0}) ->
  Errors =
  lists:flatten(
    lists:map(
      fun(#{topic := Topic, partition_errors := PartitionErrors}) ->
          lists:map(
            fun(#{partition := Partition, error_code := ErrorCode}) ->
                case ErrorCode =:= ?no_error of
                  true  -> [];
                  false -> {Topic, Partition, ErrorCode}
                end
            end, PartitionErrors)
      end, Errors0)),
  case Errors =:= [] of
    true -> ok;
    _ -> {error, Errors}
  end.

make_txn_ctx(Connection, TxnId,
             #{ error_code := ?no_error
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


ok_or_error_tuple(?no_error) -> ok;
ok_or_error_tuple(EC) -> {error, EC}.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
