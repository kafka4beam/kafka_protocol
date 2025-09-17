%%%   Copyright (c) 2018-2021, Klarna Bank AB (publ)
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

-include("kpro_private.hrl").

-define(IS_STRUCT_SCHEMA(Schema), is_list(Schema)).

%% @doc Decode message body binary (without the leading 4-byte correlation ID).
-spec decode(kpro:api(), kpro:vsn(), binary(),
             false | reference()) -> kpro:rsp().
decode(API, Vsn, Body0, Ref) ->
  Body =
    case Vsn >= kpro_schema:min_flexible_vsn(API) of
      true ->
        %% Discard tagged feilds for response header for now
        %% As it currently not used and there is no clear plan
        %% that it will be used in the near future.
        {_TaggedFields, B} = dec(tagged_fields, Body0),
        B;
      false ->
        Body0
    end,
  {Message, <<>>} =
    try
      decode_struct(API, Vsn, Body)
    catch error : E ?BIND_STACKTRACE(Stack) ->
      Context = [ {api, API}
                , {vsn, Vsn}
                , {body, Body}
                ],
      ?GET_STACKTRACE(Stack),
      erlang:raise(error, {E, Context}, Stack)
    end,
  #kpro_rsp{ ref = Ref
           , api = API
           , vsn = Vsn
           , msg = Message
           }.

%% @doc Decode struct.
dec_struct([], Fields, _Stack, Bin) ->
  {Fields, Bin};
dec_struct([{Name, FieldSc} | Schema], Fields, Stack, Bin) ->
  NewStack = [Name | Stack],
  {Value0, Rest} = dec_struct_field(FieldSc, NewStack, Bin),
  Value = translate(NewStack, Value0),
  dec_struct(Schema, Fields#{Name => Value}, Stack, Rest).

%%%_* Internal functions =======================================================

%% Decode primitives.
dec(Type, Bin) -> kpro_lib:decode(Type, Bin).

decode_struct(API, Vsn, Bin) ->
  Schema = kpro_lib:get_rsp_schema(API, Vsn),
  dec_struct(Schema, #{}, _Stack = [{API, Vsn}], Bin).

%% A struct field should have one of below types:
%% 1. An array of any
%% 2. Another struct
%% 3. A user define decoder
%% 4. A primitive
dec_struct_field({A, Schema}, Stack, Bin0) when A =:= array orelse
                                                A =:= compact_array ->
  {Count, Bin} =
    case A of
      array ->
        dec(int32, Bin0);
      compact_array ->
        {C, B} = dec(unsigned_varint, Bin0),
        {C - 1, B}
    end,
  case Count =:= -1 of
    true -> {?null, Bin};
    false -> dec_array_elements(Count, Schema, Stack, Bin, [])
  end;
dec_struct_field(Schema, Stack, Bin) when ?IS_STRUCT_SCHEMA(Schema) ->
  dec_struct(Schema, #{}, Stack, Bin);
dec_struct_field(F, _Stack, Bin) when is_function(F) ->
  %% Caller provided decoder
  F(Bin);
dec_struct_field(Primitive, DecodeStack, Bin) when is_atom(Primitive) ->
  try
    dec(Primitive, Bin)
  catch
    error : Reason ?BIND_STACKTRACE(CallStack) ->
      ?GET_STACKTRACE(CallStack),
      erlang:raise(error, {Primitive, Bin, DecodeStack, Reason}, CallStack)
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
translate([partition_error_code | _], ErrorCode) ->
  kpro_schema:ec(ErrorCode);
translate([acknowledge_error_code | _], ErrorCode) ->
  kpro_schema:ec(ErrorCode);
translate([metadata, members | _] = Stack, Bin) ->
  Schema = kpro_lib:get_prelude_schema(cg_member_metadata, 0),
  case Bin =:= <<>> of
    true  -> ?kpro_cg_no_member_metadata;
    false -> dec_struct_clean(Schema, [{cg_member_metadata, 0} | Stack], Bin)
  end;
translate([assignment | _], <<>>) ->
  ?kpro_cg_no_assignment; %% no assignment for this member
translate([assignment | _] = Stack, Bin) ->
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
