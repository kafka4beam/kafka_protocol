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

-module(kpro_rsp_lib).

-export([ decode/1
        ]).

-include("kpro_private.hrl").

-define(IS_STRUCT_SCHEMA(Schema), is_list(Schema)).

%% @doc Parse binary stream received from kafka broker.
%% Return a list of kpro:rsp() and the remaining bytes.
%% @end
-spec decode(binary()) -> {[kpro:rsp()], binary()}.
decode(Bin) ->
  decode(Bin, []).

%%%_* Internal functions =======================================================

%% Decode prmitives.
dec(Type, Bin) -> kpro_lib:decode(Type, Bin).

%% ecode struct.
dec_struct([], Fields, _Stack, Bin) ->
  {lists:reverse(Fields), Bin};
dec_struct([{Name, FieldSc} | Schema], Fields, Stack, Bin) ->
  NewStack = [Name | Stack],
  {Value0, Rest} = dec_struct_field(FieldSc, NewStack, Bin),
  Value = translate(NewStack, Value0),
  dec_struct(Schema, [{Name, Value} | Fields], Stack, Rest).

%% Decode struct having schema predefined in kpro_schema.
decode_struct(Tag, Vsn, Bin) ->
  decode_struct(?SCHEMA_MODULE, Tag, Vsn, Bin).

%% Decode struct having schema predefined in a callback:
%% Module:get(Tag, Vsn)
decode_struct(Module, Tag, Vsn, Bin) ->
  Schema = kpro:get_schema(Module, Tag, Vsn),
  dec_struct(Schema, _Fields = [], _Stack = [{Tag, Vsn}], Bin).

decode(Bin, Acc) ->
  case do_decode(Bin) of
    {incomplete, Rest} ->
      {lists:reverse(Acc), Rest};
    {Response, Rest} ->
      decode(Rest, [Response | Acc])
  end.

%% Decode responses received from kafka broker.
%% {incomplete, TheOriginalBinary} is returned if this is not a complete packet.
do_decode(<<Size:32/?INT, Bin/binary>>) when size(Bin) >= Size ->
  << ApiKey:?API_KEY_BITS,
     Vsn:?API_VERSION_BITS,
     CorrId:?CORR_ID_BITS,
     Rest0/binary >> = Bin,
  Tag = ?API_KEY_TO_RSP(ApiKey),
  {Message, Rest} =
    try
      decode_struct(Tag, Vsn, Rest0)
    catch error : E ->
      Context = [ {tag, Tag}
                , {vsn, Vsn}
                , {corr_id, CorrId}
                , {payload, Bin}
                ],
      Trace = erlang:get_stacktrace(),
      erlang:raise(error, {E, Context}, Trace)
    end,
  Result =
    #kpro_rsp{ tag = Tag
             , vsn = Vsn
             , corr_id = CorrId
             , msg = Message
             },
  {Result, Rest};
do_decode(Bin) ->
  {incomplete, Bin}.

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
  dec_struct(Schema, [], Stack, Bin);
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
  ?API_KEY_TO_REQ(ApiKey);
translate([error_code | _], ErrorCode) ->
  kpro_error_code:decode(ErrorCode);
translate([member_metadata | _] = Stack, Bin) ->
  Schema = kpro:get_schema(?PRELUDE, cg_member_metadata, 0),
  case Bin =:= <<>> of
    true  -> ?kpro_cg_no_member_metadata;
    false -> dec_struct_clean(Schema, [{cg_member_metadata, 0} | Stack], Bin)
  end;
translate([member_assignment | _], <<>>) ->
  ?kpro_cg_no_assignment; %% no assignment for this member
translate([member_assignment | _] = Stack, Bin) ->
  Schema = kpro:get_schema(?PRELUDE, cg_memeber_assignment, 0),
  dec_struct_clean(Schema, [{cg_memeber_assignment, 0} | Stack], Bin);
translate([api_key | _], ApiKey) ->
  ?API_KEY_TO_REQ(ApiKey);
translate([isolation_level | _], Integer) ->
  ?ISOLATION_LEVEL_ATOM(Integer);
translate(_Stack, Value) ->
  Value.

%% Decode struct, assume no tail bytes.
dec_struct_clean(Schema, Stack, Bin) ->
  {Fields, <<>>} = dec_struct(Schema, [], Stack, Bin),
  Fields.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
