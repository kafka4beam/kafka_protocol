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

-module(kpro_lib).

-export([ copy_bytes/2
        , data_size/1
        , decode/2
        , decode_corr_id/1
        , encode/2
        , find/2
        , find/3
        , get_prelude_schema/2
        , get_req_schema/2
        , get_rsp_schema/2
        , get_ts_type/2
        , keyfind/3
        , now_ts/0
        , ok_pipe/1
        , ok_pipe/2
        , parse_endpoints/2
        , produce_api_vsn_to_magic_vsn/1
        , send_and_recv/5
        , send_and_recv_raw/4
        , update_map/4
        , with_timeout/2
        ]).

-include("kpro_private.hrl").

-define(IS_BYTE(I), (I>=0 andalso I<256)).

-type primitive_type() :: kpro:primitive_type().
-type primitive() :: kpro:primitive().
-type count() :: non_neg_integer().

%%%_* APIs =====================================================================

-spec produce_api_vsn_to_magic_vsn(kpro:vsn()) -> kpro:magic().
produce_api_vsn_to_magic_vsn(0) -> 0;
produce_api_vsn_to_magic_vsn(V) ->
  case V < ?MIN_MAGIC_2_PRODUCE_API_VSN of
    true -> 1;
    false -> 2
  end.

%% @doc Send a raw packet to broker and wait for response raw packet.
-spec send_and_recv_raw(iodata(), port(), module(), timeout()) -> binary().
send_and_recv_raw(Req, Sock, Mod, Timeout) ->
  Opts = [{active, false}],
  case Mod of
    gen_tcp -> ok = inet:setopts(Sock, Opts);
    ssl -> ok = ssl:setopts(Sock, Opts)
  end,
  ok = Mod:send(Sock, Req),
  case Mod:recv(Sock, _Len = 0, Timeout) of
    {ok, Rsp} -> Rsp;
    {error, Reason} -> erlang:error(Reason)
  end.

%% @doc Send request to active = false socket, and wait for response.
-spec send_and_recv(kpro:req(), port(), module(),
                    kpro:client_id(), timeout()) -> kpro:struct().
send_and_recv(#kpro_req{api = API, vsn = Vsn} = Req,
                 Sock, Mod, ClientId, Timeout) ->
  CorrId = make_corr_id(),
  ReqBin = kpro_req_lib:encode(ClientId, CorrId, Req),
  try
    RspBin = send_and_recv_raw(ReqBin, Sock, Mod, Timeout),
    {CorrId, Body} = decode_corr_id(RspBin), %% assert match CorrId
    #kpro_rsp{api = API, vsn = Vsn, msg = Msg} = %% assert match API and Vsn
      kpro_rsp_lib:decode(API, Vsn, Body, _DummyRef = false),
    Msg
  catch
    error : Reason ?BIND_STACKTRACE(Stack) ->
      ?GET_STACKTRACE(Stack),
      erlang:raise(error, {Req, Reason}, Stack)
  end.

%% @doc Function pipeline.
%% The first function takes no args, all succeeding ones shoud be arity-0 or 1
%% functions. All functions should retrun
%% `ok' | `{ok, Result}' | `{error, Reason}'.
%% where `Result' is the input arg of the next function,
%% or the result of pipeline if it's the last pipe node.
%%
%% NOTE: If a funcition returns `ok' the next should be an arity-0 function.
%%       Any `{error, Reason}' return value would cause the pipeline to abort.
%%
%% NOTE: The pipe funcions are delegated to an agent process to evaluate,
%%       only exceptions and process links are propagated back to caller
%%       other side-effects like monitor references are not handled.
ok_pipe(FunList, Timeout) ->
  with_timeout(fun() -> do_ok_pipe(FunList) end, Timeout).

%% @doc Same as `ok_pipe/2' with `infinity' as default timeout.
ok_pipe(FunList) ->
  ok_pipe(FunList, infinity).

%% @doc Parse comma separated endpoints in a string into a list of
%% `{Host::string(), Port::integer()}' pairs.
%% Endpoints may start with protocol prefix (non case sensitive):
%% `PLAINTEXT://', `SSL://', `SASL_PLAINTEXT://' or `SASL_SSL://'.
%% The first arg is to filter desired endpoints from parse result.
-spec parse_endpoints(kpro:protocol() | undefined, string()) ->
        [kpro:endpoint()].
parse_endpoints(Protocol, Str) ->
  lists:foldr(
    fun(EP, Acc) ->
        case EP =/= "" andalso parse_endpoint(string:to_lower(EP)) of
          {Protocol, Endpoint} -> [Endpoint | Acc];
          _ -> Acc
        end
    end, [], string:tokens(Str, ",\n")).

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
  Size = data_size(B),
  case Size =:= 0 of
    true  -> <<-1:32/?INT>>;
    false -> [<<Size:32/?INT>>, B]
  end;
encode(records, B) ->
  encode(bytes, B).

%% @doc All kafka messages begin with a 32 bit correlation ID.
-spec decode_corr_id(binary()) -> {kpro:corr_id(), binary()}.
decode_corr_id(<<ID:32/unsigned-integer, Body/binary>>) ->
  {ID, Body}.

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
-spec copy_bytes(-1 | count(), binary()) -> {binary(), binary()}.
copy_bytes(-1, Bin) ->
  {<<>>, Bin};
copy_bytes(Size, Bin) ->
  <<Bytes:Size/binary, Rest/binary>> = Bin,
  {binary:copy(Bytes), Rest}.

-spec get_ts_type(byte(), byte()) -> kpro:ts_type().
get_ts_type(0, _) -> undefined;
get_ts_type(_, A) when ?KPRO_IS_CREATE_TS(A) -> create;
get_ts_type(_, A) when ?KPRO_IS_APPEND_TS(A) -> append.

%% os:system_time(millisecond) is since otp 19
-spec now_ts() -> kpro:msg_ts().
now_ts() -> os:system_time() div 1000000.

-spec get_req_schema(kpro:api(), kpro:vsn()) -> kpro:struct_schema().
get_req_schema(Api, Vsn) ->
  F = fun() -> kpro_schema:req(Api, Vsn) end,
  get_schema(F, {Api, req, Vsn}).

-spec get_rsp_schema(kpro:api(), kpro:vsn()) -> kpro:struct_schema().
get_rsp_schema(Api, Vsn) ->
  F = fun() -> kpro_schema:rsp(Api, Vsn) end,
  get_schema(F, {Api, rsp, Vsn}).

-spec get_prelude_schema(atom(), kpro:vsn()) -> kpro:struct_schema().
get_prelude_schema(Tag, Vsn) ->
  F = fun() -> kpro_prelude_schema:get(Tag, Vsn) end,
  get_schema(F, {Tag, Vsn}).

%% @doc Find struct filed value.
%% Error exception `{not_struct, TheInput}' is raised when
%% the input is not a `kpro:struct()'.
%% Error exception `{no_such_field, FieldName}' is raised when
%% the field is not found.
-spec find(kpro:field_name(), kpro:struct()) -> kpro:field_value().
find(Field, Struct) when is_map(Struct) ->
  try
    maps:get(Field, Struct)
  catch
    error : {badkey, _} ->
      erlang:error({no_such_field, Field})
  end;
find(Field, Struct) when is_list(Struct) ->
  case lists:keyfind(Field, 1, Struct) of
    {_, Value} -> Value;
    false -> erlang:error({no_such_field, Field})
  end;
find(_Field, Other) ->
  erlang:error({not_struct, Other}).

%% @doc Find struct field value, return `Default' if the field is not found.
-spec find(kpro:filed_name(), kpro:struct(), kpro:field_value()) ->
        kpro:field_value().
find(Field, Struct, Default) ->
  try
    find(Field, Struct)
  catch
    error : {no_such_field, _} ->
      Default
  end.

%% @doc Equivalent to `maps:update_with/4' (since otp 19).
update_map(Key, Fun, Init, Map) ->
  case Map of
    #{Key := Value} -> Map#{Key := Fun(Value)};
    _ -> Map#{Key => Init}
  end.

%% @doc delegate function evaluation to an agent process
%% abort if it does not finish in time.
%% exceptions and linked processes are caught in agent process
%% and propagated to parent process
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
            C : E ?BIND_STACKTRACE(Stack) ->
              ?GET_STACKTRACE(Stack),
              CrashContext = {C, E, Stack},
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

%% @doc Find in a list for a struct having a given field value.
%% exception if the given field name is not found.
%% return 'false' if no such struct exists.
-spec keyfind(kpro:field_name(), kpro:field_value(), [kpro:struct()]) ->
        false | kpro:struct().
keyfind(FieldName, FieldValue, Structs) ->
  Pred = fun(Struct) ->
             find(FieldName, Struct) =:= FieldValue
         end,
  find_first(Pred, Structs).

%%%_* Internals ================================================================

find_first(_Pred, []) -> false;
find_first(Pred, [Struct | Rest]) ->
  case Pred(Struct) of
    true -> Struct;
    false -> find_first(Pred, Rest)
  end.

parse_endpoint("plaintext://" ++ HostPort) ->
  {plaintext, parse_host_port(HostPort)};
parse_endpoint("ssl://" ++ HostPort) ->
  {ssl, parse_host_port(HostPort)};
parse_endpoint("sasl_ssl://" ++ HostPort) ->
  {sasl_ssl, parse_host_port(HostPort)};
parse_endpoint("sasl_plaintext://" ++ HostPort) ->
  {sasl_plaintext, parse_host_port(HostPort)};
parse_endpoint(HostPort) ->
  {undefined, parse_host_port(HostPort)}.

parse_host_port(HostPort) ->
  case string:tokens(HostPort, ":") of
    [Host] ->
      {Host, 9092};
    [Host, Port] ->
      {Host, list_to_integer(Port)}
  end.

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

do_ok_pipe([Fun | FunList]) ->
  do_ok_pipe(FunList, Fun()).

do_ok_pipe([], Result) -> Result;
do_ok_pipe([Fun | FunList], ok) ->
  do_ok_pipe(FunList, Fun());
do_ok_pipe([Fun | FunList], {ok, LastOkResult}) ->
  do_ok_pipe(FunList, Fun(LastOkResult));
do_ok_pipe(_FunList, {error, Reason}) ->
  {error, Reason}.

make_corr_id() -> rand:uniform(1 bsl 31).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
