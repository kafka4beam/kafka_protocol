%% Socket fixtures use synthetic credentials and Kafka packet-4 frames.
-module(kpro_compatibility_SUITE).
-compile(export_all).
-compile(nowarn_export_all).
-include_lib("eunit/include/eunit.hrl").
-include("kpro.hrl").

all() -> [jmq, authenticate_v1, plain_final_token, authenticate_v0, raw,
          missing_versions, missing_authenticate, query_disabled, raw_nonempty, raw_closed, capped_versions, incompatible_versions, long_lifetime, callback_long_lifetime,
          unauthenticated, callback, callback_legacy, legacy_auth, auth_error, closed, timeout,
          correlation_id, truncated, invalid_array, api_error,
          scram, bad_scram_signature, reauthentication].

init_per_testcase(_, Config) ->
  process_flag(trap_exit, true),
  Config.
end_per_testcase(_, _) -> ok.

jmq(_) -> success(#{tail => <<0:32>>, token => <<"final-token">>}).
authenticate_v1(_) -> success(#{}).
plain_final_token(_) -> success(#{authenticate => {0, 0}, token => <<"final-token">>}).
authenticate_v0(_) -> success(#{authenticate => {0, 0}}).
raw(_) -> success(#{handshake => {0, 0}, authenticate => {2, 3}}).
missing_versions(_) -> success(#{handshake => missing, authenticate => missing}).
missing_authenticate(_) -> success(#{authenticate => missing}).
query_disabled(_) ->
  with_broker(#{}, fun(Port) ->
      {ok, Pid} = kpro_connection:start("127.0.0.1", Port,
          #{sasl => plain(), query_api_versions => false}),
      Events = flush_events(),
      ?assert(lists:member({request, sasl_handshake, 0}, Events)),
      ?assertEqual([], [E || {request, sasl_authenticate, _} = E <- Events]),
      ok = kpro_connection:stop(Pid)
    end).
raw_nonempty(_) -> failure(#{handshake => {0, 0}, raw_token => <<"unexpected">>}).
raw_closed(_) -> failure(#{handshake => {0, 0}, raw_close => true}).
capped_versions(_) -> success(#{handshake => {0, 5}, authenticate => {0, 5}}).
incompatible_versions(_) ->
  lists:foreach(fun(Options) ->
      with_broker(Options, fun(Port) ->
          API = case Options of #{handshake := _} -> sasl_handshake; _ -> sasl_authenticate end,
          ?assertMatch({error, {#{reason := incompatible_version_ranges, api := API,
                                 supported := {0, 1}, received := {2, 3}}, _}}, connect(Port, plain()))
        end)
    end, [#{handshake => {2, 3}}, #{authenticate => {2, 3}}]).
unauthenticated(_) ->
  lists:foreach(fun(Options) -> with_broker(Options, fun(Port) ->
      {ok, Pid} = connect(Port, undefined),
      ok = kpro_connection:stop(Pid)
    end) end, [#{handshake => missing, authenticate => missing},
                #{handshake => {2, 3}, authenticate => {2, 3}}]).
callback(_) ->
  lists:foreach(fun(Options) ->
      with_broker(Options, fun(Port) ->
          {ok, Pid} = connect(Port, {callback, ?MODULE, self()}),
          receive {callback, Vsn} -> ?assertEqual(advertised_handshake(Options), Vsn)
          after 1000 -> ct:fail(no_callback) end,
          ok = kpro_connection:stop(Pid)
        end)
    end, [#{handshake => missing, authenticate => missing},
          #{handshake => {0, 1}, authenticate => {2, 3}},
          #{handshake => {0, 5}, authenticate => {2, 3}}]).
callback_legacy(_) ->
  with_broker(#{authenticate => {2, 3}}, fun(Port) ->
      {ok, Pid} = connect(Port, {callback, kpro_compatibility_callback, self()}),
      receive {callback6, <<"test-client">>} -> ok
      after 1000 -> ct:fail(no_legacy_callback) end,
      ok = kpro_connection:stop(Pid)
    end).

auth(_, _, _Vsn, _, _, _, #{owner := Owner, lifetime := Lifetime}) ->
  Owner ! callback_authenticated,
  {ok, #{session_lifetime_ms => Lifetime}};
auth(_, _, Vsn, _, _, _, Owner) -> Owner ! {callback, Vsn}, ok.
long_lifetime(_) -> success(#{lifetime => 9223372036854775807}).
callback_long_lifetime(_) ->
  with_broker(#{}, fun(Port) ->
      {ok, Pid} = connect(Port, {callback, ?MODULE, #{owner => self(), lifetime => 9223372036854775807}}),
      receive callback_authenticated -> ok after 1000 -> ct:fail(no_callback) end,
      ?assertMatch({ok, #kpro_rsp{}}, kpro:request_sync(Pid,
          kpro_req_lib:make(metadata, 0, [{topics, []}]), 1000)),
      ok = kpro_connection:stop(Pid)
    end).
legacy_auth(_) ->
  lists:foreach(fun(Token) -> with_broker(#{authenticate => {0, 0}, token => Token}, fun(Port) ->
      {ok, Sock} = gen_tcp:connect("127.0.0.1", Port, [binary, {packet, 4}, {active, false}]),
      ok = kpro_sasl:auth("127.0.0.1", Sock, gen_tcp, <<"test-client">>, 1000, plain(), 1),
      gen_tcp:close(Sock)
    end) end, [<<>>, <<"final-token">>]).
auth_error(_) -> failure(#{error => 58}).
closed(_) -> failure(#{failure => closed}).
timeout(_) -> failure(#{failure => timeout}).
correlation_id(_) -> failure(#{correlation_offset => 1}).
truncated(_) -> failure(#{versions_body => <<0:16, 1:32, 17:16>>}).
invalid_array(_) -> failure(#{versions_body => <<0:16, -1:32/signed>>}).
api_error(_) -> failure(#{versions_body => <<35:16, 0:32>>}).
scram(_) ->
  lists:foreach(fun(Mechanism) ->
      success(#{mechanism => Mechanism, lifetime => 0}),
      success(#{mechanism => Mechanism, handshake => {0,0}})
    end, [scram_sha_256, scram_sha_512]).
bad_scram_signature(_) ->
  failure(#{mechanism => scram_sha_256, bad_signature => true}),
  ?assertEqual(2, length([E || {request, sasl_authenticate, 1} = E <- flush_events()])).
reauthentication(_) ->
  with_broker(#{lifetime => 200, metadata_delay => 250}, fun(Port) ->
      {ok, Pid} = connect(Port, plain()),
      flush_events(),
      Req1 = kpro_req_lib:make(metadata, 0, [{topics, []}]),
      Req2 = kpro_req_lib:make(metadata, 0, [{topics, []}]),
      ok = kpro:request_async(Pid, Req1),
      receive {request, metadata, 0} -> ok after 1000 -> ct:fail(no_request) end,
      timer:sleep(120),
      ok = kpro:request_async(Pid, Req2),
      receive {response, metadata} -> ok after 1000 -> ct:fail(no_response) end,
      receive {request, sasl_handshake, 1} -> ok after 1000 -> ct:fail(no_reauthentication) end,
      receive {msg, Pid, #kpro_rsp{ref = Ref1}} -> ?assertEqual(Req1#kpro_req.ref, Ref1)
      after 1000 -> ct:fail(first_request_lost) end,
      receive {msg, Pid, #kpro_rsp{ref = Ref2}} -> ?assertEqual(Req2#kpro_req.ref, Ref2)
      after 1500 -> ct:fail(queued_request_lost) end,
      ok = kpro_connection:stop(Pid)
    end).

plain() -> {plain, <<"test-user">>, <<"test-password">>}.
connect(Port, Sasl) ->
  kpro_connection:start("127.0.0.1", Port,
      #{sasl => Sasl, connect_timeout => 400, client_id => <<"test-client">>}).
success(Options) ->
  with_broker(Options, fun(Port) ->
      Mechanism = maps:get(mechanism, Options, plain),
      {ok, Pid} = connect(Port, {Mechanism, <<"test-user">>, <<"test-password">>}),
      Req = kpro_req_lib:make(metadata, 0, [{topics, []}]),
      ?assertMatch({ok, #kpro_rsp{}}, kpro:request_sync(Pid, Req, 1000)),
      Events = flush_events(),
      HV = expected_handshake(Options),
      ?assert(lists:member({request, sasl_handshake, HV}, Events)),
      AVs = [V || {request, sasl_authenticate, V} <- Events],
      case HV of
        0 -> ?assertEqual([], AVs);
        _ -> ?assertEqual([expected_authenticate(Options)], lists:usort(AVs))
      end,
      timer:sleep(120),
      ?assertEqual([], [E || {request, sasl_handshake, _} = E <- flush_events()]),
      ok = kpro_connection:stop(Pid)
    end).
failure(Options) ->
  with_broker(Options, fun(Port) ->
      Mechanism = maps:get(mechanism, Options, plain),
      ?assertMatch({error, _}, connect(Port, {Mechanism, <<"test-user">>, <<"test-password">>}))
    end).
advertised_handshake(Options) ->
  case maps:get(handshake, Options, {0, 1}) of missing -> 0; {_, Max} -> Max end.
expected_handshake(Options) -> expected_version(handshake, Options).
expected_authenticate(Options) -> expected_version(authenticate, Options).
expected_version(Key, Options) ->
  case maps:get(Key, Options, {0, 1}) of missing -> 0; {_, Max} -> min(1, Max) end.
flush_events() ->
  receive {request, _, _} = E -> [E | flush_events()];
          {response, _} = E -> [E | flush_events()]
  after 0 -> [] end.

with_broker(Options, Fun) ->
  {ok, Listener} = gen_tcp:listen(0, [binary, {packet, 4}, {active, false}, {ip, {127,0,0,1}}]),
  {ok, Port} = inet:port(Listener),
  Owner = self(),
  Broker = spawn_link(fun() ->
      {ok, Sock} = gen_tcp:accept(Listener),
      loop(Sock, Owner, Options)
    end),
  try Fun(Port)
  after gen_tcp:close(Listener), exit(Broker, shutdown) end.
loop(Sock, Owner, Options) ->
  case gen_tcp:recv(Sock, 0, 3000) of
    {ok, <<Key:16, Vsn:16, Corr0:32, Len:16, _Client:Len/binary, Body/binary>>} ->
      API = kpro_schema:api_key(Key),
      Owner ! {request, API, Vsn},
      Corr = Corr0 + maps:get(correlation_offset, Options, 0),
      NewOptions = respond(API, Vsn, Corr, Body, Sock, Owner, Options),
      loop(Sock, Owner, NewOptions);
    {error, _} -> gen_tcp:close(Sock)
  end.
respond(api_versions, 0, Corr, _, Sock, _, Options) ->
  Entries = [<<Key:16, Min:16, Max:16>> || {Key, {Min, Max}} <-
      [{17, maps:get(handshake, Options, {0,1})}, {36, maps:get(authenticate, Options, {0,1})}]],
  Versions = iolist_to_binary(Entries),
  Default = <<0:16, (length(Entries)):32, Versions/binary>>,
  Body = maps:get(versions_body, Options, Default),
  Tail = maps:get(tail, Options, <<>>),
  ok = gen_tcp:send(Sock, <<Corr:32, Body/binary, Tail/binary>>), Options;
respond(sasl_handshake, Vsn, Corr, _, Sock, _, Options) ->
  Mechanism = case maps:get(mechanism, Options, plain) of
      plain -> <<"PLAIN">>; scram_sha_256 -> <<"SCRAM-SHA-256">>; scram_sha_512 -> <<"SCRAM-SHA-512">> end,
  ok = gen_tcp:send(Sock, <<Corr:32, 0:16, 1:32, (byte_size(Mechanism)):16, Mechanism/binary>>),
  case Vsn of
    0 -> raw_auth(Sock, Options);
    _ -> ok
  end,
  maps:remove(scram_signature, Options);
respond(sasl_authenticate, Vsn, Corr, <<Len:32, Token:Len/binary>>, Sock, _, Options) ->
  ?assertEqual(expected_authenticate(Options), Vsn),
  {Reply, NewOptions} = auth_token(Token, Options),
  EC = maps:get(error, Options, 0),
  Lifetime = maps:get(lifetime, Options, 0),
  Body = <<Corr:32, EC:16, -1:16/signed, (byte_size(Reply)):32, Reply/binary>>,
  Packet = case Vsn of 0 -> Body; 1 -> <<Body/binary, Lifetime:64>> end,
  case maps:get(failure, Options, none) of
    closed -> gen_tcp:close(Sock);
    timeout -> receive after 1000 -> ok end;
    none -> ok = gen_tcp:send(Sock, Packet)
  end, NewOptions;
respond(metadata, 0, Corr, _, Sock, Owner, Options) ->
  timer:sleep(maps:get(metadata_delay, Options, 0)),
  ok = gen_tcp:send(Sock, <<Corr:32, 0:32, 0:32>>),
  Owner ! {response, metadata}, Options.

raw_auth(Sock, Options) ->
  {ok, Token} = gen_tcp:recv(Sock, 0, 1000),
  {Reply0, NewOptions} = auth_token(Token, Options),
  Reply = maps:get(raw_token, Options, Reply0),
  case maps:get(raw_close, Options, false) of
    true -> gen_tcp:close(Sock);
    false ->
      ok = gen_tcp:send(Sock, Reply),
      case maps:is_key(scram_signature, NewOptions) andalso
           not maps:is_key(scram_signature, Options) of
        true -> raw_auth(Sock, NewOptions);
        false -> ok
      end
  end.

auth_token(Token, #{mechanism := Mechanism} = Options) when Mechanism =/= plain ->
  case maps:find(scram_signature, Options) of
    {ok, Signature} ->
      ?assertMatch(<<"c=biws,r=", _/binary>>, Token),
      {<<"v=", Signature/binary>>, Options};
    error ->
      <<"n,,", Bare/binary>> = Token,
      [_, <<"r=", Nonce/binary>>] = binary:split(Bare, <<",">>),
      ServerNonce = <<Nonce/binary, "server">>,
      First = <<"r=", ServerNonce/binary, ",s=c2FsdA==,i=4096">>,
      Final = <<"c=biws,r=", ServerNonce/binary>>,
      Message = <<Bare/binary, ",", First/binary, ",", Final/binary>>,
      Sha = case Mechanism of scram_sha_256 -> sha256; scram_sha_512 -> sha512 end,
      Size = byte_size(crypto:hash(Sha, <<>>)),
      Salted = crypto:pbkdf2_hmac(Sha, <<"test-password">>, <<"salt">>, 4096, Size),
      Key = crypto:mac(hmac, Sha, Salted, <<"Server Key">>),
      Signature = case maps:get(bad_signature, Options, false) of
          true -> base64:encode(<<0:256>>);
          false -> base64:encode(crypto:mac(hmac, Sha, Key, Message)) end,
      {First, Options#{scram_signature => Signature}}
  end;
auth_token(<<0, "test-user", 0, "test-password">>, Options) ->
  {maps:get(token, Options, <<>>), Options}.
