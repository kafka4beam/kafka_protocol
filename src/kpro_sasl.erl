%%%
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

%% @doc This module implements SASL (Simple Authentication and Security Layer)
%% for kafka authentication.

-module(kpro_sasl).

-export([ auth/7
        ]).

-include("kpro_private.hrl").

-define(undef, undefined).
-define(REASON(Reason), {sasl_auth_error, Reason}).
-define(ERROR(Reason), erlang:error(?REASON(Reason))).

%%%_* API ======================================================================

auth(_Host, _Sock, _Mod, _ClientId, _Timeout, ?undef, _Vsn) ->
  %% no auth
  ok;
auth(Host, Sock, Mod, ClientId, Timeout,
     {callback, ModuleName, Opts}, _Vsn) ->
  case kpro_auth_backend:auth(ModuleName, Host, Sock, Mod,
                              ClientId, Timeout, Opts) of
    ok ->
      ok;
    {error, Reason} ->
      ?ERROR(Reason)
  end;
auth(_Host, Sock, Mod, ClientId, Timeout, Opts, HandshakeVsn) ->
  Mechanism = mechanism(Opts),
  ok = handshake(Sock, Mod, Timeout, ClientId, Mechanism, HandshakeVsn),
  %% Send and receive raw bytes
  SendRecvRaw =
    fun(Req) ->
        try kpro_lib:send_and_recv_raw(Req, Sock, Mod, Timeout)
        catch
          error : Reason ?BIND_STACKTRACE(Stack) ->
            ?GET_STACKTRACE(Stack),
            ?ERROR({Reason, Stack})
        end
    end,
  %% Embed raw bytes in sasl_auth_bytes field.
  SendRecv =
    fun(Bytes) ->
        Req = kpro_req_lib:make(sasl_authenticate, _AuthReqVsn = 0,
                                [{sasl_auth_bytes, Bytes}]),
        Rsp = kpro_lib:send_and_recv(Req, Sock, Mod, ClientId, Timeout),
        EC = kpro:find(error_code, Rsp),
        case EC =:= ?no_error of
          true -> kpro:find(sasl_auth_bytes, Rsp);
          false -> ?ERROR(kpro:find(error_message, Rsp))
                   end
    end,
  %% For version 0 handshake, the following auth request/responses
  %% are sent raw (without kafka protocol schema wrapper)
  %% For version 1 handshake, the following auth request/responses
  %% are wrapped by kafka protocol schema
  %% Version 1 has more informative error message comparing to version 0
  case HandshakeVsn =:= 0 of
    true -> do_auth(SendRecvRaw, Opts, HandshakeVsn);
    false -> do_auth(SendRecv, Opts, HandshakeVsn)
  end.

%%%_* Internal functions =======================================================

do_auth(SendRecv, {plain, User, Pass}, Vsn) ->
  Req = sasl_plain_token(User, Pass),
  try
    <<>> = SendRecv(Req),
    ok
  catch
    error : ?REASON({closed, _Stack}) when Vsn =:= 0 ->
      %% in version 0 (bare sasl bytes)
      %% bad credentials result in a remote socket close
      %% turn it into a more informative error code
      ?ERROR(bad_credentials)
  end;
do_auth(SendRecv, {Scram, User, Pass}, _) when ?IS_SCRAM(Scram) ->
  Sha = case Scram of
          ?scram_sha_256 -> sha256;
          ?scram_sha_512 -> sha512
        end,
  Scram1 = kpro_scram:init(Sha, User, Pass),
  %% make client first message
  CFirst = kpro_scram:first(Scram1),
  %% send client first message and receive server first message
  ServerFirstMsg = SendRecv(CFirst),
  %% parse server first message
  Scram2 = kpro_scram:parse(Scram1, ServerFirstMsg),
  %% make client final message
  ClientFinalMsg = kpro_scram:final(Scram2),
  %% send client final message and receive server final message
  ServerFinalMsg = SendRecv(ClientFinalMsg),
  %% Validate server signature
  ok = kpro_scram:validate(Scram2, ServerFinalMsg);
do_auth(_SendRecv, Unknown, _) ->
  ?ERROR({unknown_sasl_opt, Unknown}).

handshake(Sock, Mod, Timeout, ClientId, Mechanism, Vsn) ->
  Req = kpro_req_lib:make(sasl_handshake, Vsn, [{mechanism, Mechanism}]),
  Rsp = kpro_lib:send_and_recv(Req, Sock, Mod, ClientId, Timeout),
  ErrorCode = kpro:find(error_code, Rsp),
  case ErrorCode of
    ?no_error ->
      ok;
    unsupported_sasl_mechanism ->
      EnabledMechanisms = kpro:find(enabled_mechanisms, Rsp),
      Msg = io_lib:format("sasl mechanism ~s is not enabled in kafka, "
                          "enabled mechanism(s): ~s",
                          [Mechanism, cs(EnabledMechanisms)]),
      ?ERROR(iolist_to_binary(Msg));
    Other ->
      ?ERROR(Other)
  end.

sasl_plain_token(User, Pass) ->
  iolist_to_binary([0, User, 0, Pass]).

mechanism(?plain) -> <<"PLAIN">>;
mechanism(?scram_sha_256) -> <<"SCRAM-SHA-256">>;
mechanism(?scram_sha_512) -> <<"SCRAM-SHA-512">>;
mechanism({Tag, _User, _Pass}) -> mechanism(Tag).

cs([]) -> "[]";
cs([X]) -> X;
cs([H | T]) -> [H, "," | cs(T)].

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
