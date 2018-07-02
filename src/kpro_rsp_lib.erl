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

-module(kpro_rsp_lib).

-export([ decode/4
        , dec_struct/4
        ]).

-export([ parse/1
        ]).

-include("kpro_private.hrl").

-define(IS_STRUCT_SCHEMA(Schema), is_list(Schema)).

%% @doc Decode message body binary (without the leading 4-byte correlation ID).
-spec decode(kpro:api(), kpro:vsn(), binary(),
             false | reference()) -> kpro:rsp().
decode(API, Vsn, Body, Ref) ->
  {Message, <<>>} =
    try
      decode_struct(API, Vsn, Body)
    catch error : E ->
      Context = [ {api, API}
                , {vsn, Vsn}
                , {body, Body}
                ],
      Trace = erlang:get_stacktrace(),
      erlang:raise(error, {E, Context}, Trace)
    end,
  #kpro_rsp{ ref = Ref
           , api = API
           , vsn = Vsn
           , msg = Message
           }.

-spec parse(kpro:rsp()) -> term().
parse(#kpro_rsp{ api = list_offsets
               , msg = Msg
               }) ->
  case get_partition_rsp(Msg) of
    #{offsets := [Offset]} = M -> M#{offset => Offset};
    #{offset := _} = M -> M
  end;
parse(#kpro_rsp{ api = produce
               , msg = Msg
               }) ->
  get_partition_rsp(Msg);
parse(#kpro_rsp{ api = fetch
               , vsn = Vsn
               , msg = Msg
               }) ->
  EC1 = kpro:find(error_code, Msg, ?no_error),
  SessionID = kpro:find(session_id, Msg, 0),
  {Header, Batches, EC2} =
    case kpro:find(responses, Msg) of
      [] ->
        %% a session init without data
        {undefined, [], ?no_error};
      _ ->
        PartitionRsp = get_partition_rsp(Msg),
        Header0 = kpro:find(partition_header, PartitionRsp),
        Records = kpro:find(record_set, PartitionRsp),
        ECx = kpro:find(error_code, Header0),
        {Header0, decode_batches(Vsn, Records), ECx}
    end,
  ErrorCode = case EC2 =:= ?no_error of
                true  -> EC1;
                false -> EC2
              end,
  #{ error_code => ErrorCode
   , session_id => SessionID
   , header => Header
   , batches => Batches
   };
parse(#kpro_rsp{ api = create_topics
               , msg = Msg
               }) ->
  error_if_any(kpro:find(topic_errors, Msg));
parse(#kpro_rsp{ api = delete_topics
               , msg = Msg
               }) ->
  error_if_any(kpro:find(topic_error_codes, Msg));
parse(#kpro_rsp{ api = create_partitions
               , msg = Msg
               }) ->
  error_if_any(kpro:find(topic_errors, Msg));
parse(#kpro_rsp{msg = Msg}) ->
  Msg.

%% @doc Decode struct.
dec_struct([], Fields, _Stack, Bin) ->
  {Fields, Bin};
dec_struct([{Name, FieldSc} | Schema], Fields, Stack, Bin) ->
  NewStack = [Name | Stack],
  {Value0, Rest} = dec_struct_field(FieldSc, NewStack, Bin),
  Value = translate(NewStack, Value0),
  dec_struct(Schema, Fields#{Name => Value}, Stack, Rest).

%%%_* Internal functions =======================================================

%% Return ok if all error codes are 'no_error'
%% otherwise return {error, Errors} where Errors is a list of error codes
error_if_any(Errors) ->
  Pred = fun(Struct) -> kpro:find(error_code, Struct) =/= ?no_error end,
  case lists:filter(Pred, Errors) of
    [] -> ok;
    Errs -> erlang:error(Errs)
  end.

decode_batches(Vsn, <<>>) when Vsn >= ?MIN_MAGIC_2_FETCH_API_VSN ->
  %% when it's magic v2, there is no incomplete batch
  [];
decode_batches(_Vsn, Bin) ->
  kpro:decode_batches(Bin).

get_partition_rsp(Struct) ->
  [TopicRsp] = kpro:find(responses, Struct),
  [PartitionRsp] = kpro:find(partition_responses, TopicRsp),
  PartitionRsp.

%% Decode prmitives.
dec(Type, Bin) -> kpro_lib:decode(Type, Bin).

decode_struct(API, Vsn, Bin) ->
  Schema = kpro_lib:get_rsp_schema(API, Vsn),
  dec_struct(Schema, #{}, _Stack = [{API, Vsn}], Bin).

%% A struct field should have one of below types:
%% 1. An array of any
%% 2. Another struct
%% 3. A user define decoder
%% 4. A primitive
dec_struct_field({array, Schema}, Stack, Bin0) ->
  {Count, Bin} = dec(int32, Bin0),
  case Count =:= -1 of
    true -> {?null, Bin};
    false -> dec_array_elements(Count, Schema, Stack, Bin, [])
  end;
dec_struct_field(Schema, Stack, Bin) when ?IS_STRUCT_SCHEMA(Schema) ->
  dec_struct(Schema, #{}, Stack, Bin);
dec_struct_field(F, _Stack, Bin) when is_function(F) ->
  %% Caller provided decoder
  F(Bin);
dec_struct_field(Primitive, Stack, Bin) when is_atom(Primitive) ->
  try
    dec(Primitive, Bin)
  catch
    error : _Reason ->
      erlang:error({Stack, Primitive, Bin})
  end.

dec_array_elements(0, _Schema, _Stack, Bin, Acc) ->
  {lists:reverse(Acc), Bin};
dec_array_elements(N, Schema, Stack, Bin, Acc) ->
  {Element, Rest} = dec_struct_field(Schema, Stack, Bin),
  dec_array_elements(N-1, Schema, Stack, Rest, [Element | Acc]).

%% Translate error codes; Dig up embedded bytes. etc.
translate([api_key | _], ApiKey) ->
  try
    kpro_schema:api_key(ApiKey)
  catch
    error : {not_supported, _}->
      %% Not supported, perhaps a broker-only API, discard
      ApiKey
  end;
translate([error_code | _], ErrorCode) ->
  kpro_schema:ec(ErrorCode);
translate([member_metadata | _] = Stack, Bin) ->
  Schema = kpro_lib:get_prelude_schema(cg_member_metadata, 0),
  case Bin =:= <<>> of
    true  -> ?kpro_cg_no_member_metadata;
    false -> dec_struct_clean(Schema, [{cg_member_metadata, 0} | Stack], Bin)
  end;
translate([member_assignment | _], <<>>) ->
  ?kpro_cg_no_assignment; %% no assignment for this member
translate([member_assignment | _] = Stack, Bin) ->
  Schema = kpro_lib:get_prelude_schema(cg_memeber_assignment, 0),
  dec_struct_clean(Schema, [{cg_memeber_assignment, 0} | Stack], Bin);
translate([isolation_level | _], Integer) ->
  ?ISOLATION_LEVEL_ATOM(Integer);
translate(_Stack, Value) ->
  Value.

%% Decode struct, assume no tail bytes.
dec_struct_clean(Schema, Stack, Bin) ->
  {Fields, <<>>} = dec_struct(Schema, #{}, Stack, Bin),
  Fields.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
