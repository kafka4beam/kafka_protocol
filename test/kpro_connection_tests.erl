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
-module(kpro_connection_tests).

-include_lib("eunit/include/eunit.hrl").
-include("kpro_private.hrl").

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

no_api_version_query_test() ->
  Config = #{query_api_versions => false},
  {ok, Pid} = connect(Config),
  ?assertEqual({ok, undefined}, kpro_connection:get_api_vsns(Pid)),
  ok = kpro_connection:stop(Pid).

extra_sock_opts_test() ->
  Config = #{query_api_versions => false,
             extra_sock_opts => [{delay_send, true}]},
  {ok, Pid} = connect(Config),

  {ok, Sock} = kpro_connection:get_tcp_sock(Pid),
  {ok, InetSockOpts} = inet:getopts(Sock, [delay_send]),
  ?assertEqual(true, proplists:get_value(delay_send, InetSockOpts)),
  ok = kpro_connection:stop(Pid).

connect(Config) ->
  Protocol = kpro_test_lib:guess_protocol(Config),
  [{Host, Port} | _] = kpro_test_lib:get_endpoints(Protocol),
  kpro_connection:start(Host, Port, Config).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
