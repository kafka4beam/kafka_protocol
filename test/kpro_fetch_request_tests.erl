-module(kpro_fetch_request_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro.hrl").

-define(TOPIC, <<"test-topic">>).
-define(PARTI, 0).
-define(HOST, "localhost").
-define(TIMEOUT, 5000).

fetch_request_v6_test() ->
  Vsn = 6,
  {ok, Pid} = kpro_connection:start(self(), ?HOST, 9092, #{}),
  try
    Req = make_req(Vsn),
    {ok, Rsp} = kpro:request_sync(Pid, Req, ?TIMEOUT),
    #kpro_rsp{ tag = fetch_response
             , vsn = Vsn
             , msg = Msg
             } = Rsp,
    [Response] = kpro:find(responses, Msg),
    [PartitionResponse] = kpro:find(partition_responses, Response),
    PartitionHeader = kpro:find(partition_header, PartitionResponse),
    RecordSetBin = kpro:find(record_set, PartitionResponse),
    ?assertEqual(no_error, kpro:find(error_code, PartitionHeader)),
    Records = kpro:decode_batches(RecordSetBin),
    io:format(user, "~p", [Records])
  after
    kpro_connection:stop(Pid)
  end.

make_req(Vsn) ->
  kpro:fetch_request(Vsn, ?TOPIC, ?PARTI, 0, 10000, 0, 12,
                     _IsolationLevel = 1).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
