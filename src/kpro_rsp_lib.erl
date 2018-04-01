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

-export([ decode_corr_id/1
        , decode_body/3
        ]).

-export([ parse/1
        ]).

-include("kpro_private.hrl").

-define(IS_STRUCT_SCHEMA(Schema), is_list(Schema)).

%% @doc Decode byte stream into a list of `{correlation_id, message_body}'
%% tuples. It is unable to decode `message_body' binary because we do not know
%% what message type it is. Only after a lookup with `correlation_id'
%% to find the sent request type, can we decode the message body.
-spec decode_corr_id(binary()) -> {[{kpro:corr_id(), binary()}], binary()}.
decode_corr_id(Bin) ->
  decode_corr_id(Bin, []).

%% @doc Decode body binary.
-spec decode_body(kpro:api(), kpro:vsn(), binary()) -> kpro:rsp().
decode_body(API, Vsn, Body) ->
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
  #kpro_rsp{ api = API
           , vsn = Vsn
           , msg = Message
           }.

-spec parse(kpro:rsp()) -> {ok, kpro:offset()} | {error, any()}.
parse(#kpro_rsp{ api = list_offsets
               , msg = Msg
               }) ->
  case kpro_lib:struct_to_map(get_partition_rsp(Msg)) of
    #{offsets := [Offset]} = M -> M#{offset => Offset};
    #{offset := _} = M -> M
  end;
parse(#kpro_rsp{ api = produce
               , msg = Msg
               }) ->
  kpro_lib:struct_to_map(get_partition_rsp(Msg));
parse(#kpro_rsp{ api = fetch
               , msg = Msg
               }) ->
  PartitionRsp = get_partition_rsp(Msg),
  Header = kpro:find(partition_header, PartitionRsp),
  Records = kpro:find(record_set, PartitionRsp),
  #{ header => kpro_lib:struct_to_map(Header)
   , batches => kpro:decode_batches(Records)
   };
parse(Rsp) ->
  %% Not supported yet
  Rsp.

%%%_* Internal functions =======================================================

get_partition_rsp(Struct) ->
  [TopicRsp] = kpro:find(responses, Struct),
  [PartitionRsp] = kpro:find(partition_responses, TopicRsp),
  PartitionRsp.

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

decode_struct(API, Vsn, Bin) ->
  Schema = kpro_lib:get_rsp_schema(API, Vsn),
  dec_struct(Schema, _Fields = [], _Stack = [{API, Vsn}], Bin).

decode_corr_id(Bin, Acc) ->
  case do_decode_corr_id(Bin) of
    {incomplete, Rest} ->
      {lists:reverse(Acc), Rest};
    {Response, Rest} ->
      decode_corr_id(Rest, [Response | Acc])
  end.

%% Decode responses received from kafka broker.
%% {incomplete, TheOriginalBinary} is returned if this is not a complete packet.
do_decode_corr_id(<<Size:32/?INT, Bin:Size/binary, Rest/binary>>) ->
  <<CorrId:32/unsigned-integer, MsgBody/binary>> = Bin,
  {{CorrId, MsgBody}, Rest};
do_decode_corr_id(Bin) ->
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
  ?API_KEY_ATOM(ApiKey);
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
