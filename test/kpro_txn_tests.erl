% This eunit module tests below APIs:
% find_coordinator (txn)
% init_producer_id,
% add_partitions_to_txn,
% add_offsets_to_txn,
% end_txn,
% txn_offset_commit,

-module(kpro_txn_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro_private.hrl").

-define(TIMEOUT, 5000).

txn_producer_test() ->
  {ok, Versions} = with_connection(fun(Pid) -> kpro:get_api_versions(Pid) end),
  {Min, Max} = maps:get(produce, Versions),
  {_, MaxFetchVsn} = maps:get(fetch, Versions),
  case Max >= 3 of
    true -> test_txn_producer(rand(Min, Max), MaxFetchVsn);
    false -> io:format(user, "skipped (vsn = ~p)", [Max])
  end.

test_txn_producer(ProduceReqVsn, FetchVsn) ->
  Topic = topic(),
  Partition = partition(),
  FetchReqFun =
    fun(Offset, IsolationLevel) ->
        kpro_req_lib:fetch(FetchVsn, Topic, Partition,
                           Offset, 500, 0, 10000, IsolationLevel)
    end,
  TxnId = make_transactional_id(),
  % find_coordinator (txn)
  {ok, Conn} = connect_coordinator(TxnId),
  % init_producer_id
  {ok, TxnCtx} = init_txn_ctx(Conn, TxnId),
  % add_partitions_to_txn
  ok = kpro:send_txn_partitions(TxnCtx, [{Topic, Partition}]),
  % produce
  Batches = produce_messages(ProduceReqVsn, TxnCtx),
  % fetch (with isolation_level = read_uncommitted)
  ok = fetch_and_verify(FetchReqFun, Batches, read_uncommitted),
  % end_txn
  ok = kpro:commit_txn(TxnCtx),
  % fetch (with isolation_level = read_committed)
  ok = fetch_and_verify(FetchReqFun, Batches, read_committed),
  ok = kpro:close_connection(Conn),
  ok.

%%%_* Helpers ==================================================================

init_txn_ctx(Conn, TxnId) ->
  case kpro:init_txn_ctx(Conn, TxnId) of
    {error, ?EC_COORDINATOR_NOT_AVAILABLE} ->
      % kafka will have to create the internal topic for
      % transaction state logs for the first time there is a
      % find transactional coordinator request received.
      % it may fail with a 'coordinator not available' error for this first
      % request. herer we try again to ensure test deterministic
      kpro:init_txn_ctx(Conn, TxnId);
    Other ->
      Other
  end.

fetch_and_verify(FetchReqFun, [{Offset0, _} | _] = Batches, IsolationLevel) ->
  ExpectedMessages = lists:append([Msgs || {_Offset, Msgs} <- Batches]),
  with_connection_to_partition_leader(
    fun(Connection) ->
        FetchAndVerif =
          fun(Offset, Exp) ->
              Req = FetchReqFun(Offset, IsolationLevel),
              {ok, Rsp} = kpro:request_sync(Connection, Req, ?TIMEOUT),
              #{batches := Batches0} = kpro_rsp_lib:parse(Rsp),
              Messages = lists:append([Msgs || {_Meta, Msgs} <- Batches0]),
              verify_messages(Offset, Messages, Exp)
          end,
        fetch_and_verify(FetchAndVerif, {Offset0, ExpectedMessages})
    end).

fetch_and_verify(_FetchAndVerif, done) -> ok;
fetch_and_verify(FetchAndVerif, {Offset, ExpectedMessages}) ->
  Next = FetchAndVerif(Offset, ExpectedMessages),
  fetch_and_verify(FetchAndVerif, Next).

%% returns 'done' when done verification
%% otherwise return next offset and remaining expectations
verify_messages(_Offset, _Messages, []) -> done;
verify_messages(Offset,
                [#kafka_message{ offset = Offset
                               , key = Key
                               , value = Value
                               } | Messages],
                [#{ key := Key
                  , value := Value
                  } | ExpectedMessages]) ->
  verify_messages(Offset + 1, Messages, ExpectedMessages);
verify_messages(Offset, [], ExpectedMessages) ->
  {Offset, ExpectedMessages}.

produce_messages(ProduceReqVsn, TxnCtx) ->
  Topic = topic(),
  Partition = partition(),
  ReqFun =
    fun(Seqno, Batch) ->
        Opts = #{txn_ctx => TxnCtx, first_sequence => Seqno},
        kpro_req_lib:produce(ProduceReqVsn, Topic, Partition, Batch, Opts)
    end,
  Seqno0 = 0,
  Batch0 = make_random_batch(),
  Req0 = ReqFun(Seqno0, Batch0),
  Seqno1 = length(Batch0),
  Batch1 = make_random_batch(),
  Req1 = ReqFun(Seqno1, Batch1),
  with_connection_to_partition_leader(
    fun(Connection) ->
        {ok, Rsp0} = kpro:request_sync(Connection, Req0, ?TIMEOUT),
        #{ error_code := no_error
         , base_offset := Offset0
         } = kpro_rsp_lib:parse(Rsp0),
        {ok, Rsp1} = kpro:request_sync(Connection, Req1, ?TIMEOUT),
        #{ error_code := no_error
         , base_offset := Offset1
         } = kpro_rsp_lib:parse(Rsp1),
        [{Offset0, Batch0}, {Offset1, Batch1}]
    end).

with_connection_to_partition_leader(Fun) ->
  ConnFun =
    fun(Endpoints, Cfg) ->
        kpro:connect_partition_leader(Endpoints, Cfg, topic(), partition())
    end,
  with_connection(ConnFun, Fun).

with_connection(F) ->
  kpro_test_lib:with_connection(F).

with_connection(ConnectF, F) ->
  kpro_test_lib:with_connection(ConnectF, F).

topic() -> kpro_test_lib:get_topic().

partition() -> 0.

make_random_batch() ->
  N = rand(10),
  [#{ key => integer_to_binary(I)
    , value => term_to_binary(os:system_time())
    } || I <- lists:seq(0, N)
  ].

connect_coordinator(ProducerId) ->
  Cluster = kpro_test_lib:get_endpoints(ssl),
  ConnCfg = kpro_test_lib:connection_config(ssl),
  Args = #{type => txn, id => ProducerId},
  kpro:connect_coordinator(Cluster, ConnCfg, Args).

%% Make a random transactional id, so test cases would not interfere each other.
make_transactional_id() ->
  bin([atom_to_list(?MODULE), "-", bin(rand())]).

rand() -> rand:uniform(1000000).

rand(N) -> rand() rem N.

rand(Min, Max) ->
  Min + rand(Max - Min + 1).

bin(I) when is_integer(I) -> integer_to_binary(I);
bin(Str) -> iolist_to_binary(Str).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
