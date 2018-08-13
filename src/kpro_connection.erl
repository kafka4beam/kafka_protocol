%%%
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

-module(kpro_connection).

%% API
-export([ all_cfg_keys/0
        , get_api_vsns/1
        , get_endpoint/1
        , get_tcp_sock/1
        , init/4
        , loop/2
        , request_sync/3
        , request_async/2
        , send/2
        , start/3
        , stop/1
        , debug/2
        ]).

%% system calls support for worker process
-export([ system_continue/3
        , system_terminate/4
        , system_code_change/4
        , format_status/2
        ]).

-export_type([ config/0
             , connection/0
             ]).

-include("kpro_private.hrl").

-define(DEFAULT_CONNECT_TIMEOUT, timer:seconds(5)).
-define(DEFAULT_REQUEST_TIMEOUT, timer:minutes(4)).
-define(SIZE_HEAD_BYTES, 4).

-type cfg_key() :: connect_timeout
                 | client_id
                 | extra_sock_opts
                 | debug
                 | nolink
                 | query_api_versions
                 | request_timeout
                 | sasl
                 | ssl.

-type cfg_val() :: term().
-type config() :: [{cfg_key(), cfg_val()}] | #{cfg_key() => cfg_val()}.
-type requests() :: kpro_sent_reqs:requests().
-type hostname() :: kpro:hostname().
-type portnum()  :: kpro:portnum().
-type client_id() :: kpro:client_id().
-type connection() :: pid().

-define(undef, undefined).

-record(state, { client_id   :: client_id()
               , parent      :: pid()
               , remote      :: kpro:endpoint()
               , sock        :: gen_tcp:socket() | ssl:sslsocket()
               , mod         :: ?undef | gen_tcp | ssl
               , req_timeout :: ?undef | timeout()
               , api_vsns    :: ?undef | kpro:vsn_ranges()
               , requests    :: ?undef | requests()
               }).

-type state() :: #state{}.

%%%_* API ======================================================================

%% @doc Return all config keys make client config management easy.
-spec all_cfg_keys() -> [cfg_key()].
all_cfg_keys() ->
  [ connect_timeout, debug, client_id, request_timeout, sasl, ssl,
    nolink, query_api_versions, extra_sock_opts
  ].

%% @doc Connect to the given endpoint.
%% The started connection pid is linked to caller
%% unless `nolink := true' is found in `Config'
-spec start(hostname(), portnum(), config()) -> {ok, pid()} | {error, any()}.
start(Host, Port, Config) when is_list(Config) ->
  start(Host, Port, maps:from_list(Config));
start(Host, Port, #{nolink := true} = Config) ->
  proc_lib:start(?MODULE, init, [self(), host(Host), Port, Config]);
start(Host, Port, Config) ->
  proc_lib:start_link(?MODULE, init, [self(), host(Host), Port, Config]).

%% @doc Same as @link request_async/2.
%% Only that the message towards connection process is a cast (not a call).
%% Always return 'ok'.
-spec send(connection(), kpro:req()) -> ok.
send(Pid, Request) ->
  erlang:send(Pid, {{self(), noreply}, {send, Request}}),
  ok.

%% @doc Send a request. Caller should expect to receive a response
%% having `Rsp#kpro_rsp.ref' the same as `Request#kpro_req.ref'
%% unless `Request#kpro_req.no_ack' is set to 'true'
-spec request_async(connection(), kpro:req()) -> ok | {error, any()}.
request_async(Pid, Request) ->
  call(Pid, {send, Request}).

%% @doc Send a request and wait for response for at most Timeout milliseconds.
-spec request_sync(connection(), kpro:req(), timeout()) ->
        ok | {ok, kpro:rsp()} | {error, any()}.
request_sync(Pid, Request, Timeout) ->
  case request_async(Pid, Request) of
    ok when Request#kpro_req.no_ack ->
      ok;
    ok ->
      wait_for_rsp(Pid, Request, Timeout);
    {error, Reason} ->
      {error, Reason}
  end.

%% @doc Stop socket process.
-spec stop(connection()) -> ok | {error, any()}.
stop(Pid) when is_pid(Pid) ->
  call(Pid, stop);
stop(_) ->
  ok.

-spec get_api_vsns(pid()) ->
        {ok, ?undef | kpro:vsn_ranges()} | {error, any()}.
get_api_vsns(Pid) ->
  call(Pid, get_api_vsns).

-spec get_endpoint(pid()) -> {ok, kpro:endpoint()} | {error, any()}.
get_endpoint(Pid) ->
  call(Pid, get_endpoint).

%% @hidden
-spec get_tcp_sock(pid()) -> {ok, port()}.
get_tcp_sock(Pid) ->
  call(Pid, get_tcp_sock).

%% @doc Enable/disable debugging on the socket process.
%%      debug(Pid, pring) prints debug info on stdout
%%      debug(Pid, File) prints debug info into a File
%%      debug(Pid, none) stops debugging
-spec debug(connection(), print | string() | none) -> ok.
debug(Pid, none) ->
  system_call(Pid, {debug, no_debug});
debug(Pid, print) ->
  system_call(Pid, {debug, {trace, true}});
debug(Pid, File) when is_list(File) ->
  system_call(Pid, {debug, {log_to_file, File}}).

%%%_* Internal functions =======================================================

-spec init(pid(), hostname(), portnum(), config()) -> no_return().
init(Parent, Host, Port, Config) ->
  State =
    try
      State0 = connect(Parent, Host, Port, Config),
      ReqTimeout = get_request_timeout(Config),
      ok = send_assert_max_req_age(self(), ReqTimeout),
      Requests = kpro_sent_reqs:new(),
      State0#state{requests = Requests, req_timeout = ReqTimeout}
    catch
      error : Reason ?BIND_STACKTRACE(Stack) ->
        ?GET_STACKTRACE(Stack),
        IsSsl = maps:get(ssl, Config, false),
        SaslOpt = get_sasl_opt(Config),
        ok = maybe_log_hint(Host, Port, Reason, IsSsl, SaslOpt),
        proc_lib:init_ack(Parent, {error, {Reason, Stack}}),
        erlang:exit(normal)
    end,
  %% From now on, enter `{active, once}' mode
  %% NOTE: ssl doesn't support `{active, N}'
  ok = setopts(State#state.sock, State#state.mod, [{active, once}]),
  Debug = sys:debug_options(maps:get(debug, Config, [])),
  proc_lib:init_ack(Parent, {ok, self()}),
  loop(State, Debug).

%% Connect to the given endpoint, then initalize connection.
%% Raise an error exception for any failure.
-spec connect(pid(), hostname(), portnum(), config()) -> state().
connect(Parent, Host, Port, Config) ->
  Timeout = get_connect_timeout(Config),
  %% initial active opt should be 'false' before upgrading to ssl
  SockOpts = [{active, false}, binary] ++ get_extra_sock_opts(Config),
  case gen_tcp:connect(Host, Port, SockOpts, Timeout) of
    {ok, Sock} ->
      State = #state{ client_id = get_client_id(Config)
                    , parent    = Parent
                    , remote    = {Host, Port}
                    , sock      = Sock
                    },
      init_connection(State, Config);
    {error, Reason} ->
      erlang:error(Reason)
  end.

%% Initialize connection.
%% * Upgrade to SSL
%% * SASL authentication
%% * Query API versions
init_connection(#state{ client_id = ClientId
                      , sock = Sock
                      , remote = {Host, _}
                      } = State, Config) ->
  Timeout = get_connect_timeout(Config),
  %% adjusting buffer size as per recommendation at
  %% http://erlang.org/doc/man/inet.html#setopts-2
  %% idea is from github.com/epgsql/epgsql
  {ok, [{recbuf, RecBufSize}, {sndbuf, SndBufSize}]} =
    inet:getopts(Sock, [recbuf, sndbuf]),
  ok = inet:setopts(Sock, [{buffer, max(RecBufSize, SndBufSize)}]),
  SslOpts = maps:get(ssl, Config, false),
  Mod = get_tcp_mod(SslOpts),
  NewSock = maybe_upgrade_to_ssl(Sock, Mod, SslOpts, Timeout),
  %% from now on, it's all packet-4 messages
  ok = setopts(NewSock, Mod, [{packet, 4}]),
  Versions =
    case Config of
      #{query_api_versions := false} -> ?undef;
      _ -> query_api_versions(NewSock, Mod, ClientId, Timeout)
    end,
  HandshakeVsn = case Versions of
                   #{sasl_handshake := {_, V}} -> V;
                   _ -> 0
                 end,
  SaslOpts = get_sasl_opt(Config),
  ok = kpro_sasl:auth(Host, NewSock, Mod, ClientId,
                      Timeout, SaslOpts, HandshakeVsn),
  State#state{mod = Mod, sock = NewSock, api_vsns = Versions}.

query_api_versions(Sock, Mod, ClientId, Timeout) ->
  Req = kpro_req_lib:make(api_versions, 0, []),
  Rsp = kpro_lib:send_and_recv(Req, Sock, Mod, ClientId, Timeout),
  ErrorCode = find(error_code, Rsp),
  case ErrorCode =:= ?no_error of
    true ->
      Versions = find(api_versions, Rsp),
      F = fun(V, Acc) ->
          API = find(api_key, V),
          MinVsn = find(min_version, V),
          MaxVsn = find(max_version, V),
          case is_atom(API) of
            true ->
              %% known API for client
              Acc#{API => {MinVsn, MaxVsn}};
            false ->
              %% a broker-only (ClusterAction) API
              Acc
          end
      end,
      lists:foldl(F, #{}, Versions);
    false ->
      erlang:error({failed_to_query_api_versions, ErrorCode})
  end.

get_tcp_mod(_SslOpts = true)  -> ssl;
get_tcp_mod(_SslOpts = [_|_]) -> ssl;
get_tcp_mod(_)                -> gen_tcp.

maybe_upgrade_to_ssl(Sock, _Mod = ssl, SslOpts0, Timeout) ->
  SslOpts = case SslOpts0 of
              true -> [];
              [_|_] -> SslOpts0
            end,
  case ssl:connect(Sock, SslOpts, Timeout) of
    {ok, NewSock} -> NewSock;
    {error, Reason} -> erlang:error({failed_to_upgrade_to_ssl, Reason})
  end;
maybe_upgrade_to_ssl(Sock, _Mod, _SslOpts, _Timeout) ->
  Sock.

setopts(Sock, _Mod = gen_tcp, Opts) -> inet:setopts(Sock, Opts);
setopts(Sock, _Mod = ssl, Opts)     ->  ssl:setopts(Sock, Opts).

-spec wait_for_rsp(connection(), kpro:req(), timeout()) ->
        {ok, term()} | {error, any()}.
wait_for_rsp(Pid, #kpro_req{ref = Ref}, Timeout) ->
  Mref = erlang:monitor(process, Pid),
  receive
    {msg, Pid, #kpro_rsp{ref = Ref} = Rsp} ->
      erlang:demonitor(Mref, [flush]),
      {ok, Rsp};
    {'DOWN', Mref, _, _, Reason} ->
      {error, {connection_down, Reason}}
  after
    Timeout ->
      erlang:demonitor(Mref, [flush]),
      {error, timeout}
  end.

system_call(Pid, Request) ->
  Mref = erlang:monitor(process, Pid),
  erlang:send(Pid, {system, {self(), Mref}, Request}),
  receive
    {Mref, Reply} ->
      erlang:demonitor(Mref, [flush]),
      Reply;
    {'DOWN', Mref, _, _, Reason} ->
      {error, {connection_down, Reason}}
  end.

call(Pid, Request) ->
  Mref = erlang:monitor(process, Pid),
  erlang:send(Pid, {{self(), Mref}, Request}),
  receive
    {Mref, Reply} ->
      erlang:demonitor(Mref, [flush]),
      Reply;
    {'DOWN', Mref, _, _, Reason} ->
      {error, {connection_down, Reason}}
  end.

-spec maybe_reply({pid(), reference() | noreply}, term()) -> ok.
maybe_reply({_, noreply}, _) ->
  ok;
maybe_reply({To, Ref}, Reply) ->
  _ = erlang:send(To, {Ref, Reply}),
  ok.

loop(#state{} = State, Debug) ->
  Msg = receive Input -> Input end,
  decode_msg(Msg, State, Debug).

decode_msg({system, From, Msg}, #state{parent = Parent} = State, Debug) ->
  sys:handle_system_msg(Msg, From, Parent, ?MODULE, Debug, State);
decode_msg(Msg, State, [] = Debug) ->
  handle_msg(Msg, State, Debug);
decode_msg(Msg, State, Debug0) ->
  Debug = sys:handle_debug(Debug0, fun print_msg/3, State, Msg),
  handle_msg(Msg, State, Debug).

handle_msg({_, Sock, Bin}, #state{ sock     = Sock
                                 , requests = Requests
                                 , mod      = Mod
                                 } = State, Debug) when is_binary(Bin) ->
  ok = setopts(Sock, Mod, [{active, once}]),
  {CorrId, Body} = kpro_lib:decode_corr_id(Bin),
  {Caller, Ref, API, Vsn} = kpro_sent_reqs:get_req(Requests, CorrId),
  Rsp = kpro_rsp_lib:decode(API, Vsn, Body, Ref),
  ok = cast(Caller, {msg, self(), Rsp}),
  NewRequests = kpro_sent_reqs:del(Requests, CorrId),
  ?MODULE:loop(State#state{requests = NewRequests}, Debug);
handle_msg(assert_max_req_age, #state{ requests = Requests
                                     , req_timeout = ReqTimeout
                                     } = State, Debug) ->
  SockPid = self(),
  erlang:spawn_link(fun() ->
                        ok = assert_max_req_age(Requests, ReqTimeout),
                        ok = send_assert_max_req_age(SockPid, ReqTimeout)
                    end),
  ?MODULE:loop(State, Debug);
handle_msg({tcp_closed, Sock}, #state{sock = Sock}, _) ->
  exit({shutdown, tcp_closed});
handle_msg({ssl_closed, Sock}, #state{sock = Sock}, _) ->
  exit({shutdown, ssl_closed});
handle_msg({tcp_error, Sock, Reason}, #state{sock = Sock}, _) ->
  exit({tcp_error, Reason});
handle_msg({ssl_error, Sock, Reason}, #state{sock = Sock}, _) ->
  exit({ssl_error, Reason});
handle_msg({From, {send, Request}},
           #state{ client_id = ClientId
                 , mod       = Mod
                 , sock      = Sock
                 , requests  = Requests
                 } = State, Debug) ->
  {Caller, _Ref} = From,
  {CorrId, NewRequests} =
    case Request of
      #kpro_req{no_ack = true} ->
        kpro_sent_reqs:increment_corr_id(Requests);
      #kpro_req{ref = Ref, api = API, vsn = Vsn} ->
        kpro_sent_reqs:add(Requests, Caller, Ref, API, Vsn)
    end,
  RequestBin = kpro_req_lib:encode(ClientId, CorrId, Request),
  Res = case Mod of
          gen_tcp -> gen_tcp:send(Sock, RequestBin);
          ssl     -> ssl:send(Sock, RequestBin)
        end,
  case Res of
    ok ->
      maybe_reply(From, ok);
    {error, Reason} ->
      exit({send_error, Reason})
  end,
  ?MODULE:loop(State#state{requests = NewRequests}, Debug);
handle_msg({From, get_api_vsns}, State, Debug) ->
  maybe_reply(From, {ok, State#state.api_vsns}),
  ?MODULE:loop(State, Debug);
handle_msg({From, get_endpoint}, State, Debug) ->
  maybe_reply(From, {ok, State#state.remote}),
  ?MODULE:loop(State, Debug);
handle_msg({From, get_tcp_sock}, State, Debug) ->
  maybe_reply(From, {ok, State#state.sock}),
  ?MODULE:loop(State, Debug);
handle_msg({From, stop}, #state{mod = Mod, sock = Sock}, _Debug) ->
  Mod:close(Sock),
  maybe_reply(From, ok),
  ok;
handle_msg(Msg, #state{} = State, Debug) ->
  error_logger:warning_msg("[~p] ~p got unrecognized message: ~p",
                          [?MODULE, self(), Msg]),
  ?MODULE:loop(State, Debug).

cast(Pid, Msg) ->
  try
    Pid ! Msg,
    ok
  catch _ : _ ->
    ok
  end.

system_continue(_Parent, Debug, State) ->
  ?MODULE:loop(State, Debug).

-spec system_terminate(any(), _, _, _) -> no_return().
system_terminate(Reason, _Parent, Debug, _Misc) ->
  sys:print_log(Debug),
  exit(Reason).

system_code_change(State, _Module, _Vsn, _Extra) ->
  {ok, State}.

format_status(Opt, Status) ->
  {Opt, Status}.

print_msg(Device, {_From, {send, Request}}, State) ->
  do_print_msg(Device, "send: ~p", [Request], State);
print_msg(Device, {tcp, _Sock, Bin}, State) ->
  do_print_msg(Device, "tcp: ~p", [Bin], State);
print_msg(Device, {tcp_closed, _Sock}, State) ->
  do_print_msg(Device, "tcp_closed", [], State);
print_msg(Device, {tcp_error, _Sock, Reason}, State) ->
  do_print_msg(Device, "tcp_error: ~p", [Reason], State);
print_msg(Device, {_From, stop}, State) ->
  do_print_msg(Device, "stop", [], State);
print_msg(Device, Msg, State) ->
  do_print_msg(Device, "unknown msg: ~p", [Msg], State).

do_print_msg(Device, Fmt, Args, State) ->
  CorrId = kpro_sent_reqs:get_corr_id(State#state.requests),
  io:format(Device, "[~s] ~p [~10..0b] " ++ Fmt ++ "~n",
            [ts(), self(), CorrId] ++ Args).

ts() ->
  Now = os:timestamp(),
  {_, _, MicroSec} = Now,
  {{Y, M, D}, {HH, MM, SS}} = calendar:now_to_local_time(Now),
  lists:flatten(io_lib:format("~.4.0w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w.~w",
                              [Y, M, D, HH, MM, SS, MicroSec])).

-spec get_extra_sock_opts(config()) -> [gen_tcp:connect_option()].
get_extra_sock_opts(Config) ->
  maps:get(extra_sock_opts, Config, []).

-spec get_connect_timeout(config()) -> timeout().
get_connect_timeout(Config) ->
  maps:get(connect_timeout, Config, ?DEFAULT_CONNECT_TIMEOUT).

%% Get request timeout from config.
-spec get_request_timeout(config()) -> timeout().
get_request_timeout(Config) ->
  maps:get(request_timeout, Config, ?DEFAULT_REQUEST_TIMEOUT).

-spec assert_max_req_age(requests(), timeout()) -> ok | no_return().
assert_max_req_age(Requests, Timeout) ->
  case kpro_sent_reqs:scan_for_max_age(Requests) of
    Age when Age > Timeout ->
      erlang:exit(request_timeout);
    _ ->
      ok
  end.

%% Send the 'assert_max_req_age' message to connection process.
%% The send interval is set to a half of configured timeout.
-spec send_assert_max_req_age(connection(), timeout()) -> ok.
send_assert_max_req_age(Pid, Timeout) when Timeout >= 1000 ->
  %% Check every 1 minute
  %% or every half of the timeout value if it's less than 2 minute
  SendAfter = erlang:min(Timeout div 2, timer:minutes(1)),
  _ = erlang:send_after(SendAfter, Pid, assert_max_req_age),
  ok.

%% So far supported endpoint is tuple {Hostname, Port}
%% which lacks of hint on which protocol to use.
%% It would be a bit nicer if we support endpoint formats like below:
%%    PLAINTEX://hostname:port
%%    SSL://hostname:port
%%    SASL_PLAINTEXT://hostname:port
%%    SASL_SSL://hostname:port
%% which may give some hint for early config validation before trying to
%% connect to the endpoint.
%%
%% However, even with the hint, it is still quite easy to misconfig and endup
%% with a clueless crash report.  Here we try to make a guess on what went
%% wrong in case there was an error during connection estabilishment.
maybe_log_hint(Host, Port, Reason, IsSsl, SaslOpt) ->
  case hint_msg(Reason, IsSsl, SaslOpt) of
    ?undef ->
      ok;
    Msg ->
      error_logger:error_msg("Failed to connect to ~s:~p\n~s\n",
                             [Host, Port, Msg])
  end.

hint_msg({failed_to_upgrade_to_ssl, R}, _IsSsl, SaslOpt) when R =:= closed;
                                                              R =:= timeout ->
  case SaslOpt of
    ?undef -> "Make sure connecting to a 'SSL://' listener";
    _      -> "Make sure connecting to 'SASL_SSL://' listener"
  end;
hint_msg({sasl_auth_error, 'IllegalSaslState'}, true, _SaslOpt) ->
  "Make sure connecting to 'SASL_SSL://' listener";
hint_msg({sasl_auth_error, 'IllegalSaslState'}, false, _SaslOpt) ->
  "Make sure connecting to 'SASL_PLAINTEXT://' listener";
hint_msg({sasl_auth_error, {badmatch, {error, enomem}}}, false, _SaslOpts) ->
  %% This happens when KAFKA is expecting SSL handshake
  %% but client started SASL handshake instead
  "Make sure 'ssl' option is in client config, \n"
  "or make sure connecting to 'SASL_PLAINTEXT://' listener";
hint_msg(_, _, _) ->
  %% Sorry, I have no clue, please read the crash log
  ?undef.

%% Get sasl options from connection config.
-spec get_sasl_opt(config()) -> cfg_val().
get_sasl_opt(Config) ->
  case maps:get(sasl, Config, ?undef) of
    {Mechanism, User, Pass0} when ?IS_PLAIN_OR_SCRAM(Mechanism) ->
      Pass = case is_function(Pass0) of
               true  -> Pass0();
               false -> Pass0
             end,
      {Mechanism, User, Pass};
    {Mechanism, File} when ?IS_PLAIN_OR_SCRAM(Mechanism) ->
      {User, Pass} = read_sasl_file(File),
      {Mechanism, User, Pass};
    Other ->
      Other
  end.

%% Read a regular file, assume it has two lines:
%% First line is the sasl-plain username
%% Second line is the password
-spec read_sasl_file(file:name_all()) -> {binary(), binary()}.
read_sasl_file(File) ->
  {ok, Bin} = file:read_file(File),
  Lines = binary:split(Bin, <<"\n">>, [global]),
  [User, Pass] = lists:filter(fun(Line) -> Line =/= <<>> end, Lines),
  {User, Pass}.

%% Ensure string() hostname
host(Host) when is_binary(Host) -> binary_to_list(Host);
host(Host) when is_list(Host) -> Host.

%% Ensure binary client id
get_client_id(Config) ->
  ClientId = maps:get(client_id, Config, <<"kpro-client">>),
  case is_atom(ClientId) of
    true -> atom_to_binary(ClientId, utf8);
    false -> ClientId
  end.

find(FieldName, Struct) -> kpro_lib:find(FieldName, Struct).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
