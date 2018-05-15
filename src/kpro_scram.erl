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

%% @doc This module is a simplified SCRAM client side implementation.
%% SCRAM: Salted Challenge Response Authentication Mechanism.
%% REF: https://tools.ietf.org/html/rfc5802
%% NOTE: Assumptions made in this implementation
%% 1. User names contain ascii codes only
%% 2. User names do not contain '=' or ','

-module(kpro_scram).

-export([ init/3
        , first/1
        , parse/2
        , final/1
        , validate/2
        ]).

-export_type([scram/0]).

-define(MY_NONCE_LEN, 24).
-define(GS2_HEADER, <<"n,,">>).
-define(CHANNEL_BINDING, <<"c=biws">>). % "biws" is base64 encoded "n,,"

-opaque scram() :: map().

%% @doc Initialize a scram context.
-spec init(sha256 | sha512, binary(), binary()) -> scram().
init(Sha, User, Pass) ->
  Nonce = base64:encode(crypto:strong_rand_bytes(2 * ?MY_NONCE_LEN div 3)),
  #{ sha => Sha
   , pass => Pass
   , nonce => Nonce
   , c_first_bare => bin(["n=", User, ",r=", Nonce])
   }.

%% @doc Make the fist client message.
-spec first(scram()) -> binary().
first(#{c_first_bare := Bare}) -> bin([?GS2_HEADER, Bare]).

%% @doc Parse server first message.
-spec parse(scram(), binary()) -> scram().
parse(#{ sha := Sha
       , pass := Password
       , nonce := MyNonce
       , c_first_bare := ClientFirstMsgBare
       }, ServerFirstMsg) ->
  #{ nonce := ServerNonce
   , salt := Salt0
   , i_count := Iterations
   } = parse(ServerFirstMsg),
  %% must validate that the server nonce has my nonce as prefix
  <<MyNonce:?MY_NONCE_LEN/binary, _/binary>> = ServerNonce,
  Salt = base64:decode(Salt0),
  SaltedPassword = hi(Sha, Password, Salt, Iterations),
  FinalNoProof = bin([?CHANNEL_BINDING, ",r=", Salt]),
  AuthMsg = [ClientFirstMsgBare, ",", ServerFirstMsg, ",", FinalNoProof],
  #{ sha => Sha
   , salted_password => SaltedPassword
   , finale_no_proof => FinalNoProof
   , auth_msg => bin(AuthMsg)
   , proof => proof(Sha, SaltedPassword, AuthMsg)
   }.

%% @doc Make client's final message.
-spec final(scram()) -> binary().
final(#{ finale_no_proof := FinalMsgWithoutProof
       , proof := ClientProof
       }) ->
  bin([FinalMsgWithoutProof, ",p=", ClientProof]).

%% @doc Validate server's signature.
-spec validate(scram(), binary()) -> ok.
validate(Scram, ServerFinalMsg) ->
  #{ sha := Sha
   , salted_password := SaltedPassword
   , auth_msg := AuthMessage
   } = Scram,
  #{signature := ServerSignature0} = parse(ServerFinalMsg),
  ServerSignature = base64:decode(ServerSignature0),
  HMAC = fun(A, B) -> crypto:hmac(Sha, A, B) end,
  ServerKey = HMAC(SaltedPassword, <<"Server Key">>),
  ServerSignature = HMAC(ServerKey, AuthMessage), %% assert
  ok.

%%%_* Internal functions =======================================================

proof(Sha, SaltedPassword, AuthMsg) ->
  ClientKey  = crypto:hmac(Sha, SaltedPassword, <<"Client Key">>),
  StoredKey = crypto:hash(Sha, ClientKey),
  ClientSignature = crypto:hmac(Sha, StoredKey, AuthMsg),
  ClientProof = crypto:exor(ClientKey, ClientSignature),
  base64:encode(ClientProof).

hi(Sha, Password, Salt0, Iterations) when Iterations > 0 ->
  Salt1 = <<Salt0/binary, 0, 0, 0, 1>>,
  HMAC = fun(SaltIn) -> crypto:hmac(Sha, Password, SaltIn) end,
  H1 = HMAC(Salt1),
  HL = hi(HMAC, [H1], Iterations - 1),
  lists:foldl(fun crypto:exor/2, hd(HL), tl(HL)).

hi(_, Acc, 0) -> Acc;
hi(HMAC, [H_last | _] = Acc, I) ->
  hi(HMAC, [HMAC(H_last) | Acc], I - 1).

parse(ServerMsg) ->
  Tokens = binary:split(ServerMsg, <<",">>, [global]),
  lists:foldl(fun parse_token/2, #{}, Tokens).

parse_token(<<"r=", Nonce/binary>>, Acc) -> Acc#{nonce => Nonce};
parse_token(<<"s=", Salt/binary>>, Acc) -> Acc#{salt => Salt};
parse_token(<<"i=", I/binary>>, Acc) -> Acc#{i_count => int(I)};
parse_token(<<"v=", Sig/binary>>, Acc) -> Acc#{signature => Sig};
parse_token(_, Acc) -> Acc.

int(I) -> binary_to_integer(I).

bin(S) -> iolist_to_binary(S).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:

