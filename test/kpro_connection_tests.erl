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

%% The tests below need no Kafka. They connect to a local TCP listener
%% and skip the API versions query, so no Kafka handshake happens.

-define(IPV6_LOOPBACK, {0, 0, 0, 0, 0, 0, 0, 1}).
-define(IPV4_LOOPBACK, {127, 0, 0, 1}).

ipv6_only_listener_test_() ->
  case listen(?IPV6_LOOPBACK) of
    {ok, LSock} ->
      ok = gen_tcp:close(LSock),
      {setup, fun() -> listen_port(?IPV6_LOOPBACK) end, fun close/1,
       fun({_LSock, Port}) -> ipv6_only_listener_cases(Port) end};
    {error, Reason} ->
      {"no IPv6 loopback (" ++ atom_to_list(Reason) ++ "), skipped", []}
  end.

ipv6_only_listener_cases(Port) ->
  Connect = fun(Host) -> assert_connected(Host, Port, ?IPV6_LOOPBACK) end,
  [ {"ipv6 tuple", fun() -> Connect(?IPV6_LOOPBACK) end}
  , {"ipv6 string", fun() -> Connect("::1") end}
  , {"ipv6 binary", fun() -> Connect(<<"::1">>) end}
  , {"ipv6 parsed endpoint",
     fun() ->
         [{Host, Port}] = kpro:parse_endpoints("[::1]:" ++ integer_to_list(Port)),
         Connect(Host)
     end}
  , {"ipv6 explicit inet6",
     fun() -> assert_connected("::1", Port, ?IPV6_LOOPBACK, [inet6]) end}
  ] ++
  [ {"ipv6-only hostname " ++ Name, fun() -> Connect(Name) end}
    || Name <- ipv6_loopback_names()
  ] ++
  [ {"explicit inet disables ipv6 fallback " ++ Name,
     fun() -> ?assertMatch({error, _}, start(Name, Port, [inet])) end}
    || Name <- ipv6_loopback_names()
  ].

ipv4_listener_test_() ->
  {setup, fun() -> listen_port(?IPV4_LOOPBACK) end, fun close/1,
   fun({_LSock, Port}) ->
       Connect = fun(Host) -> assert_connected(Host, Port, ?IPV4_LOOPBACK) end,
       [ {"ipv4 tuple", fun() -> Connect(?IPV4_LOOPBACK) end}
       , {"ipv4 string", fun() -> Connect("127.0.0.1") end}
       , {"ipv4 binary", fun() -> Connect(<<"127.0.0.1">>) end}
       , {"localhost", fun() -> Connect("localhost") end}
       , {"localhost atom", fun() -> Connect(localhost) end}
       ]
   end}.

unknown_host_test() ->
  ?assertMatch({error, {nxdomain, _}},
               start("kpro-no-such-host.invalid", 9092, [])).

assert_connected(Host, Port, PeerIP) ->
  assert_connected(Host, Port, PeerIP, []).

assert_connected(Host, Port, PeerIP, ExtraSockOpts) ->
  {ok, Pid} = start(Host, Port, ExtraSockOpts),
  try
    {ok, Sock} = kpro_connection:get_tcp_sock(Pid),
    ?assertEqual({ok, {PeerIP, Port}}, inet:peername(Sock)),
    %% The endpoint keeps the host as given, a binary as a string
    ?assertEqual({ok, {host_as_string(Host), Port}}, kpro_connection:get_endpoint(Pid))
  after
    ok = kpro_connection:stop(Pid)
  end.

host_as_string(Host) when is_binary(Host) -> binary_to_list(Host);
host_as_string(Host) -> Host.

start(Host, Port, ExtraSockOpts) ->
  Config = #{ query_api_versions => false
            , connect_timeout => 2000
            , extra_sock_opts => ExtraSockOpts
            },
  kpro_connection:start(Host, Port, Config).

listen_port(IP) ->
  {ok, LSock} = listen(IP),
  {ok, Port} = inet:port(LSock),
  {LSock, Port}.

close({LSock, _Port}) ->
  gen_tcp:close(LSock).

%% Connections are never accepted, so the backlog must hold all of them.
listen(?IPV6_LOOPBACK = IP) ->
  gen_tcp:listen(0, [inet6, {ip, IP}, {ipv6_v6only, true}, {backlog, 128}]);
listen(IP) ->
  gen_tcp:listen(0, [inet, {ip, IP}, {backlog, 128}]).

%% Hostnames which resolve to the IPv6 loopback only, e.g. from /etc/hosts.
%% The IPv4 lookup of these names may still return 127.0.0.1.
ipv6_loopback_names() ->
  [Name || Name <- ["ip6-localhost", "ip6-loopback"],
           resolves_to(Name, inet6, ?IPV6_LOOPBACK)].

resolves_to(Name, Family, IP) ->
  case inet:getaddrs(Name, Family) of
    {ok, IPs} -> lists:member(IP, IPs);
    {error, _} -> false
  end.

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
