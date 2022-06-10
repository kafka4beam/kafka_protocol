-module(kpro_sup).

-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() -> supervisor:start_link(?MODULE, []).

%% @doc Supervisor behaviour callback
init([]) ->
    {ok, {
        #{strategy => one_for_one, intensity => 10, period => 5}, []}
    }.
