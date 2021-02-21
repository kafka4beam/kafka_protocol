-module(kpro_app).

-behaviour(application).

-export([ start/2
        , stop/1
        ]).


%% @doc Application behaviour callback
start(_StartType, _StartArgs) ->
    Provides = application:get_env(?APPLICATION, provide_compression, []),
    kpro:provide_compression(Provides),
    {ok, self()}.

stop(_State) -> ok.
