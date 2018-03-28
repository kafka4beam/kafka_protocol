-module(kpro_lib).

-export([ copy_bytes/2
        , data_size/1
        , decode/2
        , encode/2
        , get_prelude_schema/2
        , get_req_schema/2
        , get_rsp_schema/2
        , get_ts_type/2
        , now_ts/0
        , ok_pipe/1
        , ok_pipe/2
        , parse_endpoints/1
        , with_timeout/2
        ]).

-include("kpro_private.hrl").

-define(IS_BYTE(I), (I>=0 andalso I<256)).

-type primitive_type() :: kpro:primitive_type().
-type primitive() :: kpro:primitive().
-type count() :: non_neg_integer().

%%%_* APIs =====================================================================

%% @doc Function pipeline. The fist function takes no args, all succeeding
%% functions take one arg. All functions should retrun either
%% `{ok, Result}' or `{error, Reason}'. `Result' is the input arg of the next
%% function (or the result of pipeline). Any `{error, Reason}' return value
%% would cause the pipeline to abort.
%% NOTE: The pipe funcions are delegated to an agent process to evaluate
%%       only exceptions and process links are propagated back to caller
%%       other side-effects like monitor references are not handled.
ok_pipe(FunList, Timeout) ->
  with_timeout(fun() -> do_ok_pipe(FunList) end, Timeout).

%% @doc Same as `ok_pipe/2' with `infinity' as default timeout.
ok_pipe(FunList) ->
  ok_pipe(FunList, infinity).

%% @doc Parse 'host:port,host2:port2' string into endpoint list
parse_endpoints(Str) ->
  Eps0 = string:tokens(Str, ",\n"),
  Eps = [Ep || Ep <- Eps0, Ep =/= ""],
  F = fun(Ep) ->
          case string:tokens(Ep, ":") of
            [Host] ->
              {Host, 9092};
            [Host, Port] ->
              {Host, list_to_integer(Port)}
          end
      end,
  lists:map(F, Eps).

%% @doc Return number of bytes in the given `iodata()'.
-spec data_size(iodata()) -> count().
data_size(IoData) ->
  data_size(IoData, 0).

%% @doc Encode primitives.
-spec encode(primitive_type(), kpro:primitive()) -> iodata().
encode(boolean, true) -> <<1:8/?INT>>;
encode(boolean, false) -> <<0:8/?INT>>;
encode(int8,  I) when is_integer(I) -> <<I:8/?INT>>;
encode(int16, I) when is_integer(I) -> <<I:16/?INT>>;
encode(int32, I) when is_integer(I) -> <<I:32/?INT>>;
encode(int64, I) when is_integer(I) -> <<I:64/?INT>>;
encode(varint, I) when is_integer(I) -> kpro_varint:encode(I);
encode(nullable_string, ?null) -> <<-1:16/?INT>>;
encode(nullable_string, Str) -> encode(string, Str);
encode(string, Atom) when is_atom(Atom) ->
  encode(string, atom_to_binary(Atom, utf8));
encode(string, <<>>) -> <<0:16/?INT>>;
encode(string, L) when is_list(L) ->
  encode(string, iolist_to_binary(L));
encode(string, B) when is_binary(B) ->
  Length = size(B),
  <<Length:16/?INT, B/binary>>;
encode(bytes, ?null) -> <<-1:32/?INT>>;
encode(bytes, B) when is_binary(B) orelse is_list(B) ->
  Size = kpro_lib:data_size(B),
  case Size =:= 0 of
    true  -> <<-1:32/?INT>>;
    false -> [<<Size:32/?INT>>, B]
  end;
encode(records, B) ->
  encode(bytes, B).

%% @doc Decode primitives.
-spec decode(kpro:primitive_type(), binary()) -> {primitive(), binary()}.
decode(boolean, Bin) ->
  <<Value:8/?INT, Rest/binary>> = Bin,
  {Value =/= 0, Rest};
decode(int8, Bin) ->
  <<Value:8/?INT, Rest/binary>> = Bin,
  {Value, Rest};
decode(int16, Bin) ->
  <<Value:16/?INT, Rest/binary>> = Bin,
  {Value, Rest};
decode(int32, Bin) ->
  <<Value:32/?INT, Rest/binary>> = Bin,
  {Value, Rest};
decode(int64, Bin) ->
  <<Value:64/?INT, Rest/binary>> = Bin,
  {Value, Rest};
decode(varint, Bin) ->
  kpro_varint:decode(Bin);
decode(string, Bin) ->
  <<Size:16/?INT, Rest/binary>> = Bin,
  copy_bytes(Size, Rest);
decode(bytes, Bin) ->
  <<Size:32/?INT, Rest/binary>> = Bin,
  copy_bytes(Size, Rest);
decode(nullable_string, Bin) ->
  decode(string, Bin);
decode(records, Bin) ->
  decode(bytes, Bin).

%% @doc Make a copy of the head instead of keeping referencing the original.
-spec copy_bytes(-1 | count(), binary()) -> {undefined | binary(), binary()}.
copy_bytes(-1, Bin) ->
  {undefined, Bin};
copy_bytes(Size, Bin) ->
  <<Bytes:Size/binary, Rest/binary>> = Bin,
  {binary:copy(Bytes), Rest}.

-spec get_ts_type(byte(), byte()) -> kpro:ts_type().
get_ts_type(0, _) -> undefined;
get_ts_type(_, A) when ?KPRO_IS_CREATE_TS(A) -> create;
get_ts_type(_, A) when ?KPRO_IS_APPEND_TS(A) -> append.

-spec now_ts() -> kpro:msg_ts().
now_ts() -> os:system_time(millisecond).

-spec get_req_schema(kpro:api(), kpro:vsn()) -> kpro:struct_schema().
get_req_schema(Api, Vsn) ->
  F = fun() -> kpro_schema:get(Api, req, Vsn) end,
  get_schema(F, {Api, req, Vsn}).

-spec get_rsp_schema(kpro:api(), kpro:vsn()) -> kpro:struct_schema().
get_rsp_schema(Api, Vsn) ->
  F = fun() -> kpro_schema:get(Api, rsp, Vsn) end,
  get_schema(F, {Api, rsp, Vsn}).

-spec get_prelude_schema(atom(), kpro:vsn()) -> kpro:struct_schema().
get_prelude_schema(Tag, Vsn) ->
  F = fun() -> kpro_prelude_schema:get(Tag, Vsn) end,
  get_schema(F, {Tag, Vsn}).

%%%_* Internals ================================================================

-spec data_size(iodata(), count()) -> count().
data_size([], Size) -> Size;
data_size(<<>>, Size) -> Size;
data_size(I, Size) when ?IS_BYTE(I) -> Size + 1;
data_size(B, Size) when is_binary(B) -> Size + size(B);
data_size([H | T], Size0) ->
  Size1 = data_size(H, Size0),
  data_size(T, Size1).

get_schema(F, Context) ->
  try
    F()
  catch
    error : function_clause ->
      erlang:error({unknown_type, Context})
  end.

%% delegate function evaluation to a agent process
%% abort if it does not finish in time.
%% exceptions and linked processes are caught in agent process
%% adn propagated to parent process
with_timeout(F0, Timeout) ->
  Parent = self(),
  ResultRef = make_ref(),
  AgentFun =
    fun() ->
        {links, Links0} = process_info(self(), links),
        Result =
          try
            {normal, F0()}
          catch
            C : E ->
              CrashContext = {C, E, erlang:get_stacktrace()},
              {exception, CrashContext}
          end,
        {links, Links1} = process_info(self(), links),
        Links = Links1 -- Links0,
        Parent ! {ResultRef, Result, Links},
        receive
          done ->
            %% parent is done linking to links
            %% safe to unlink and exit
            [unlink(Pid) || Pid <- Links],
            exit(normal)
        end
      end,
  Agent = erlang:spawn_link(AgentFun),
  receive
    {ResultRef, Result, Links} ->
      %% replicate links from agent
      %% TODO handle link/1 exception if any of the links are dead already
      [link(Pid) || Pid <- Links],
      unlink(Agent),
      Agent ! done,
      case Result of
        {normal, Return} ->
          Return;
        {exception, {C, E, Stacktrace}} ->
          %% replicate exception from agent
          erlang:raise(C, E, Stacktrace)
      end
  after
    Timeout ->
      %% kill agent
      unlink(Agent),
      erlang:exit(Agent, kill),
      {error, timeout}
  end.

do_ok_pipe([Fun | FunList]) ->
  do_ok_pipe(FunList, Fun()).

do_ok_pipe([], Result) -> Result;
do_ok_pipe([Fun | FunList], {ok, LastOkResult}) ->
  do_ok_pipe(FunList, Fun(LastOkResult));
do_ok_pipe(_FunList, {error, Reason}) ->
  {error, Reason}.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
