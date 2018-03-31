%% Supported versions of THIS lib
-module(kpro_api_vsn).
-export([range/1]).

-spec range(kpro:api()) -> {kpro:vsn(), kpro:vsn()}.
range(offset_commit) -> {2, 2};
range(offset_fetch) -> {1, 2};
range(API) -> kpro_schema:vsn_range(API).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
