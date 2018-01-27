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

%%%=============================================================================
%%% @doc
%%% This module manages an opaque of sent-request collection.
%%% @end
%%% ============================================================================

%% @private
-module(kpro_sent_reqs).

%%%_* Exports ==================================================================

%% API
-export([ new/0
        , add/2
        , del/2
        , get_caller/2
        , get_corr_id/1
        , increment_corr_id/1
        , scan_for_max_age/1
        ]).

-export_type([requests/0]).

-record(requests,
        { corr_id = 0
        , sent = #{}
        }).

-opaque requests() :: #requests{}.
-type corr_id() :: kpro:corr_id().

-include("kpro_private.hrl").

-define(REQ(Caller, Ts), {Caller, Ts}).
-define(MAX_CORR_ID_WINDOW_SIZE, (?MAX_CORR_ID div 2)).

%%%_* APIs =====================================================================

-spec new() -> requests().
new() -> #requests{}.

%% @doc Add a new request to sent collection.
%% Return the last corrlation ID and the new opaque.
-spec add(requests(), pid()) -> {corr_id(), requests()}.
add(#requests{ corr_id = CorrId
             , sent    = Sent
             } = Requests, Caller) ->
  NewSent = maps:put(CorrId, ?REQ(Caller, os:timestamp()), Sent),
  NewRequests = Requests#requests{ corr_id = kpro:next_corr_id(CorrId)
                                 , sent    = NewSent
                                 },
  {CorrId, NewRequests}.

%% @doc Delete a request from the opaque collection.
%% Crash if correlation ID is not found.
-spec del(requests(), corr_id()) -> requests().
del(#requests{sent = Sent} = Requests, CorrId) ->
  Requests#requests{sent = maps:remove(CorrId, Sent)}.

%% @doc Get caller of a request having the given correlation ID.
%% Crash if the request is not found.
-spec get_caller(requests(), corr_id()) -> pid().
get_caller(#requests{sent = Sent}, CorrId) ->
  ?REQ(Caller, _Ts) = maps:get(CorrId, Sent),
  Caller.

%% @doc Get the correction to be sent for the next request.
-spec get_corr_id(requests()) -> corr_id().
get_corr_id(#requests{ corr_id = CorrId }) ->
  CorrId.

%% @doc Fetch and increment the correlation ID
%% This is used if we don't want a response from the broker
-spec increment_corr_id(requests()) -> {corr_id(), requests()}.
increment_corr_id(#requests{corr_id = CorrId} = Requests) ->
  {CorrId, Requests#requests{ corr_id = kpro:next_corr_id(CorrId) }}.

%% @doc Scan all sent requests to get oldest sent request.
%% Age is in milli-seconds.
%% 0 is returned if there is no pending response.
-spec scan_for_max_age(requests()) -> timeout().
scan_for_max_age(#requests{sent = Sent}) ->
  Now = os:timestamp(),
  MinTs = maps:fold(fun(_CorrId, ?REQ(_Caller, Ts), Min) ->
                          erlang:min(Ts, Min)
                    end, Now, Sent),
  timer:now_diff(Now, MinTs) div 1000.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
