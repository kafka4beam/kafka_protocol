-module(kpro_produce_request_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro.hrl").

-define(TOPIC, <<"test-topic">>).
-define(PARTI, 0).
-define(HOST, "localhost").
-define(TIMEOUT, 5000).

magic_v0_basic_test_() ->
  MkTestFun =
    fun(Vsn) ->
        fun() ->
            {ok, Pid} = kpro_connection:start(self(), ?HOST, 9092, #{}),
            try
              Req = make_req(Vsn),
              {ok, Rsp} = kpro:request_sync(Pid, Req, ?TIMEOUT),
              #kpro_rsp{ tag = produce_response
                       , vsn = Vsn
                       , msg = [ {responses, [Response]}
                               | _
                               ]
                       } = Rsp,
              [ {topic, ?TOPIC}
              , {partition_responses, [PartitionRsp]}
              | _
              ] = Response,
              ?assertMatch([ {partition, ?PARTI}
                           , {error_code, no_error}
                           , {base_offset, _}
                           | _
                           ], PartitionRsp)
            after
              kpro_connection:stop(Pid)
            end
        end
    end,
  MkTest =
    fun(Vsn) ->
        {"batch magic version 0 in produce request version " ++
         integer_to_list(Vsn), MkTestFun(Vsn)}
    end,
  [MkTest(Vsn) || Vsn <- lists:seq(0, 5)].

make_req(Vsn) ->
  Batch = make_batch(Vsn),
  kpro:produce_request(Vsn, ?TOPIC, ?PARTI, Batch,
                       _RequiredAcks = 1,
                       _AckTimeout = 1000,
                       no_compression).

% Produce requests with version 3 are only allowed to contain record batches
% with magic version 2
make_batch(Vsn) when Vsn < 3 ->
  [ {<<"key1">>, make_value(Vsn)}
  , {<<"key2">>, make_value(Vsn)}
  ];
make_batch(Vsn) ->
  F = fun(I) ->
          #{ value => <<>>
           }
      end,
  [F(1)].

make_value(Vsn) ->
  term_to_binary({Vsn, os:system_time()}).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
