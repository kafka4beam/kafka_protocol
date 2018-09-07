%%%   Copyright (c) 2017, Klarna AB
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
-ifndef(KPRO_HRL_).
-define(KPRO_HRL_, true).

%% Header file for kafka client (brod).

-include("kpro_public.hrl").
-include("kpro_error_codes.hrl").

-record(kpro_req,
        { ref :: reference()
        , api :: kpro:api()
        , vsn :: kpro:vsn()
        , no_ack = false :: boolean() %% set to true for fire-n-forget requests
        , msg :: binary() | kpro:struct()
        }).

-record(kpro_rsp,
        { ref :: false | reference()
        , api :: kpro:api()
        , vsn :: kpro:vsn()
        , msg :: binary() | kpro:struct()
        }).

-define(incomplete_batch(ExpectedSize), {incomplete_batch, ExpectedSize}).
-define(kpro_null, undefined).
-define(kpro_cg_no_assignment, ?kpro_null).
-define(kpro_cg_no_member_metadata, ?kpro_null).
-define(kpro_read_committed, read_committed).
-define(kpro_read_uncommitted, read_uncommitted).

-define(KPRO_NO_BATCH_META, undefined).

-endif.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
