%%%
%%%   Copyright (c) 2017-2021, Klarna Bank AB (publ)
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

-module(kpro_auth_backend).

-export([auth/8]).

-callback auth(Host :: string(), Sock :: gen_tcp:socket() | ssl:sslsocket(),
               Mod :: gen_tcp | ssl, ClientName :: binary(),
               Timeout :: pos_integer(), SaslOpts :: term()) ->
                 ok | {error, Reason :: term()}.

-callback auth(Host :: string(), Sock :: gen_tcp:socket() | ssl:sslsocket(),
               HandShakeVsn :: non_neg_integer(), Mod :: gen_tcp | ssl, ClientName :: binary(),
               Timeout :: pos_integer(), SaslOpts :: term()) ->
                 ok | {error, Reason :: term()}.

-optional_callbacks([auth/6]).

-spec auth(CallbackModule :: atom(), Host :: string(),
           Sock :: gen_tcp:socket() | ssl:sslsocket(),
           Mod :: gen_tcp | ssl, ClientName :: binary(),
           Timeout :: pos_integer(), SaslOpts :: term()) ->
            ok | {error, Reason :: term()}.
auth(CallbackModule, Host, Sock, Mod, ClientName, Timeout, SaslOpts) ->
  CallbackModule:auth(Host, Sock, Mod, ClientName, Timeout, SaslOpts).

-spec auth(CallbackModule :: atom(), Host :: string(),
           Sock :: gen_tcp:socket() | ssl:sslsocket(),
           HandShakeVsn :: non_neg_integer(),
           Mod :: gen_tcp | ssl, ClientName :: binary(),
           Timeout :: pos_integer(), SaslOpts :: term()) ->
            ok | {error, Reason :: term()}.
auth(CallbackModule, Host, Sock, Vsn, Mod, ClientName, Timeout, SaslOpts) ->
    case is_exported(CallbackModule, auth, 7) of
        true ->
            CallbackModule:auth(Host, Sock, Vsn, Mod, ClientName, Timeout, SaslOpts);
        false ->
            auth(CallbackModule, Host, Sock, Mod, ClientName, Timeout, SaslOpts)
    end.

is_exported(M, F, A) ->
  case erlang:module_loaded(M) of
    false -> code:ensure_loaded(M);
    true -> ok
  end,
  erlang:function_exported(M, F, A).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
