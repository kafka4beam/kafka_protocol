%%%   Copyright (c) 2018-2021, Klarna Bank AB (publ)
%%%   Copyright (c) 2021-2025, Kafka4beam
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
-module(kpro_connection_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro_private.hrl").

-export([ auth/7 ]).

plaintext_test() ->
  Config = kpro_test_lib:connection_config(plaintext),
  {ok, Pid} = connect(Config),
  ok = kpro_connection:stop(Pid).

ssl_test() ->
  Config = kpro_test_lib:connection_config(ssl),
  {ok, Pid} = connect(Config),
  ok = kpro_connection:stop(Pid).

sasl_test() ->
  Config0 = kpro_test_lib:connection_config(ssl),
  case kpro_test_lib:get_kafka_version() of
    ?KAFKA_0_9 ->
      ok;
    ?KAFKA_0_10 ->
      Config = Config0#{sasl => kpro_test_lib:sasl_config(plain)},
      {ok, Pid} = connect(Config),
      ok = kpro_connection:stop(Pid);
    _ ->
      Config = Config0#{sasl => kpro_test_lib:sasl_config()},
      {ok, Pid} = connect(Config),
      ok = kpro_connection:stop(Pid)
  end.

sasl_file_test() ->
  Config0 = kpro_test_lib:connection_config(ssl),
  case kpro_test_lib:get_kafka_version() of
    ?KAFKA_0_9 ->
      ok;
    ?KAFKA_0_10 ->
      Config = Config0#{sasl => kpro_test_lib:sasl_config(plain_file)},
      {ok, Pid} = connect(Config),
      ok = kpro_connection:stop(Pid);
    _ ->
      Config = Config0#{sasl => kpro_test_lib:sasl_config(file)},
      {ok, Pid} = connect(Config),
      ok = kpro_connection:stop(Pid)
  end.

% SASL callback implementation for subsequent tests
auth(_Host, _Sock, _Vsn, _Mod, _ClientName, _Timeout, #{test_pid := TestPid} = SaslOpts) ->
  case SaslOpts of
    #{response_session_lifetime_ms := ResponseSessionLifeTimeMs} ->
      TestPid ! sasl_authenticated,
      {ok, #{session_lifetime_ms => ResponseSessionLifeTimeMs}};
    _ ->
      ok
  end.

sasl_callback_test() ->
  Config0 = kpro_test_lib:connection_config(sasl_ssl),
  case kpro_test_lib:get_kafka_version() of
    ?KAFKA_0_9 ->
      ok;
    _ ->
      Config = Config0#{sasl => {callback, ?MODULE, #{response_session_lifetime_ms => 51, test_pid => self()}}},
      {ok, Pid} = connect(Config),

      % initial authentication
      receive sasl_authenticated -> ok end,
      % repeated authentication as session expires
      receive sasl_authenticated -> ok end,

      ok = kpro_connection:stop(Pid)
  end.

conn_timeout_test() ->
  Config = #{connect_timeout => 10},
  {links, Links0} = erlang:process_info(self(), links),
  ?assertMatch({error, {timeout, _}}, kpro_connection:start("1.1.1.1", 9092, Config)),
  {links, Links1} = erlang:process_info(self(), links),
  ?assertEqual(lists:sort(Links0), lists:sort(Links1)).

no_api_version_query_test() ->
  Config = #{query_api_versions => false},
  {ok, Pid} = connect(Config),
  ?assertEqual({ok, undefined}, kpro_connection:get_api_vsns(Pid)),
  ?assertMatch({ok, #{}}, kpro:get_api_versions(Pid)),
  ok = kpro_connection:stop(Pid).

extra_sock_opts_test() ->
  Config = #{query_api_versions => false,
             extra_sock_opts => [{delay_send, true}]},
  {ok, Pid} = connect(Config),

  {ok, Sock} = kpro_connection:get_tcp_sock(Pid),
  {ok, InetSockOpts} = inet:getopts(Sock, [delay_send]),
  ?assertEqual(true, proplists:get_value(delay_send, InetSockOpts)),
  ok = kpro_connection:stop(Pid).

connect(Config0) ->
  Config = kpro_test_lib:connection_config(Config0),
  Protocol = kpro_test_lib:guess_protocol(Config),
  [{Host, Port} | _] = kpro_test_lib:get_endpoints(Protocol),
  kpro_connection:start(Host, Port, Config).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
