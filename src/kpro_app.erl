-module(kpro_app).

-behaviour(application).

-export([ start/2
        , stop/1
        ]).


%% @doc Application behaviour callback
start(_StartType, _StartArgs) ->
    Provides = application:get_env(kafka_protocol, provide_compression, []),
    kpro:provide_compression(Provides),
    kpro_sup:start_link().

stop(_State) -> ok.
