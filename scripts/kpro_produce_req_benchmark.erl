-module(kpro_produce_req_benchmark).
-export([run_all_scenarios/0, run_scenario/4]).

run_all_scenarios() ->
    io:format("Produce Request Encoding Performance Benchmark (magic-v2 batches, no compression) ~n"),
    io:format("====================================~n~n"),

    % Test scenarios from the plan
    Scenarios = [
        {"900KB_63B", 921600, 63, "Small values, many messages"},
        {"900KB_1KB", 921600, 1024, "Medium values, moderate messages"},
        {"900KB_10KB", 921600, 10240, "Large values, few messages"},
        {"9MB_1KB", 9437184, 1024, "Medium values, many messages"},
        {"9MB_10KB", 9437184, 10240, "Large values, moderate messages"},
        {"9MB_1MB", 9437184, 1048576, "Very large values, few messages"}
    ],

    Results = lists:map(fun({Name, TotalSize, ValueSize, Desc}) ->
        io:format("~nScenario: ~s (~s)~n", [Name, Desc]),
        run_scenario(Name, TotalSize, ValueSize, 100)
    end, Scenarios),

    % Print summary
    io:format("~n~nBenchmark Summary:~n"),
    io:format("==================~n"),
    io:format("~-12s ~-8s ~-12s ~-12s ~-12s ~-12s~n",
              ["Scenario", "Msgs", "Total(us)", "Avg(us)", "Rate(msg/s)", "MB/s"]),
    io:format("~-12s ~-8s ~-12s ~-12s ~-12s ~-12s~n",
              ["--------", "----", "----------", "--------", "----------", "-----"]),

    lists:foreach(fun({Name, Messages, TotalTime, AvgTime, Rate, DataRate}) ->
        io:format("~-12s ~-8w ~-12w ~-12w ~-12.2f ~-12.2f~n",
                  [Name, Messages, TotalTime, AvgTime, Rate, DataRate])
    end, Results),

    Results.

run_scenario(Name, TotalSize, ValueSize, Iterations) ->
    % Generate test batch
    Batch = generate_batch(TotalSize, ValueSize),
    Messages = length(Batch),

    io:format("  Generated ~w messages (~w bytes total)~n", [Messages, TotalSize]),

    % Warm up
    io:format("  Warming up...~n"),
    [kpro_req_lib:produce(8, <<"testtopic">>, 0, Batch,
                         #{ack_timeout => 1000, required_acks => all_isr, compression => no_compression})
     || _ <- lists:seq(1, 10)],

    % Run benchmark
    io:format("  Running ~w iterations...~n", [Iterations]),
    Seq = lists:seq(1, Iterations),
    StartTime = erlang:system_time(microsecond),

    lists:foreach(fun(_) ->
        kpro_req_lib:produce(8, <<"testtopic">>, 0, Batch,
        #{ack_timeout => 1000, required_acks => all_isr, compression => no_compression})
    end, Seq),

    EndTime = erlang:system_time(microsecond),
    TotalTime = EndTime - StartTime,
    AvgTime = TotalTime / Iterations,
    Rate = Messages * Iterations * 1000000 / TotalTime,
    DataRate = TotalSize * Iterations * 1000000 / TotalTime / 1024 / 1024,

    io:format("  Total time: ~w microseconds~n", [TotalTime]),
    io:format("  Average time per iteration: ~w microseconds~n", [AvgTime]),
    io:format("  Throughput: ~.2f messages/second~n", [Rate]),
    io:format("  Data rate: ~.2f MB/second~n", [DataRate]),

    {Name, Messages, TotalTime, AvgTime, Rate, DataRate}.

generate_batch(TotalSize, ValueSize) ->
    % Calculate number of messages needed
    KeySize = 32,
    Overhead = 50,
    MessageSize = ValueSize + KeySize + Overhead,
    NumMessages = max(1, TotalSize div MessageSize),

    % Generate random data
    Value = << <<(rand:uniform(255)):8>> || _ <- lists:seq(1, ValueSize) >>,
    Key = << <<(rand:uniform(255)):8>> || _ <- lists:seq(1, KeySize) >>,
    Ts = erlang:system_time(millisecond),

    [ #{key => Key, value => Value, ts => Ts} || _ <- lists:seq(1, NumMessages) ].
