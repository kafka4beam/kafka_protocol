#!/usr/bin/env escript
%% -*- erlang -*-
%%! -smp enable -sname kpro_gen

%%%
%%%   Copyright (c) 2014-2016, Klarna AB
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

%% This script reads definitions of kafka data structures from priv/kafka.bnf
%% and generates:
%%   include/kpro.hrl -- erlang record definitions of and type annotations
%%   src/kpro_structs.erl -- encoders and decoders to the wire format
%%   src/kpro_records.erl -- fields() helper to convert records to maps of maps
%%
%% Assumptions about priv/kafka.bnf: field names are unique across each top
%% level definition, so we're able to not nest names for subrecords of
%% subrecords. Subrecords and subsubrecords are indented, top level records are not.
%%
%% Top level record and type names are lowercased, changed from plural to singular,
%% "underscored", and prefixed with "kpro_":
%%   ProduceRequestV1 becomes kpro_request_v1().
%%
%% Record names for subsubrecords and types additionaly prefixed with top level
%% record name:
%%   partition_responses in responses in ProduceResponseV1 becomes
%%     kpro_produce_response_v1_partition_response().
%%
%% Field names are left exactly as they defined in kafka.bnf.

-mode(compile).

-include("../include/kpro_common.hrl").

main(_) ->
  ok = file:set_cwd(this_dir()),
  {ok, _} = leex:file(kpro_scanner),
  {ok, _} = compile:file(kpro_scanner, [debug_info]),
  {ok, _} = yecc:file(kpro_parser),
  {ok, _} = compile:file(kpro_parser, [debug_info]),
  {ok, Contents} = file:read_file("kafka.bnf"),
  {ok, Tokens, _EndLine} = kpro_scanner:string(binary_to_list(Contents)),
  {ok, DefGroups} = kpro_parser:parse(Tokens),
  Records = to_records(DefGroups),
  generate_code(Records).

this_dir() ->
  ThisScript = escript:script_name(),
  filename:dirname(ThisScript).

generate_code(Records) ->
  ok = gen_header_file(Records),
  ok = gen_records_module(Records),
  ok = gen_marshaller(Records).


to_records(DefGroups) ->
  lists:flatmap(fun records/1, DefGroups).

global_name_atom(Name) ->
  global_name_atom(kpro, Name).

global_name_atom(Namespace, Name) when is_atom(Namespace) ->
  global_name_atom(atom_to_list(Namespace), Name);
global_name_atom(Namespace, Name) when is_atom(Name) ->
  global_name_atom(Namespace, atom_to_list(Name));
global_name_atom(NamespaceStr, NameStr) ->
  list_to_atom(NamespaceStr ++ "_" ++ singular(underscorize(NameStr))).

% for a whole group
records(Defs) -> records(Defs, Defs).

% for the first (top level) record in group
records([], _Defs) -> [];
% records/2 is for top level in def group.
% this is a field expansion record:
records([{Name, Fields} | Rest], Defs) when is_list(Fields) ->
  Namespace = global_name_atom(Name),
  Rec = {Namespace, fields(Namespace, Fields, Defs)},
  [Rec | records(Namespace, Rest, Defs)];
% this is a {one_of, ...} record?
records([{Name, {one_of, Refs}} | Rest], Defs) ->
  Namespace = global_name_atom(Name),
  Rec = {global_name_atom(Name), {one_of, [global_name_atom(R) || R <- Refs]}},
  [Rec | records(Namespace, Rest, Defs)];
% skip a core type record:
records([_ | Rest], Defs) ->
  records(Rest, Defs).

records(_Namespace, [], _Defs) -> [];
% this is a field expansion record:
records(Namespace, [{Name, Fields} | Rest], Defs) when is_list(Fields) ->
  Rec = {global_name_atom(Namespace, Name), fields(Namespace, Fields, Defs)},
  [Rec | records(Namespace, Rest, Defs)];
% this is a {one_of, ...} record?
records(Namespace, [{Name, {one_of, Refs}} | Rest], Defs) ->
  Rec = {global_name_atom(Namespace, Name), {one_of, [global_name_atom(R) || R <- Refs]}},
  [Rec | records(Namespace, Rest, Defs)];
% skip a core type record:
records(Namespace, [_ | Rest], Defs) ->
  records(Namespace, Rest, Defs).

fields(Namespace, Fields, Def) ->
  lists:map(fun(Field) ->
              {field_name(Field), field_type(Namespace, Field, Def)}
            end, Fields).

field_name(Name) when is_atom(Name) -> Name;
field_name({array, Name}) -> Name.

field_type(Namespace, Name, Def) when is_atom(Name) ->
  case lists:keyfind(Name, 1, Def) of
    % false ->
    %  %% They claim the bnf to be context free, however there are still
    %  %% few cases where external reference is used, such as message set
    %  %% definition.
    %  %% FIXME doesn't work right now, should work as primitive type field
    %  global_name_atom(Name);
    {_, Fields} when is_list(Fields) ->
      %% internal reference
      global_name_atom(Namespace, Name);
    {_, {one_of, _}} ->
      %% internal reference to one_of
      global_name_atom(Namespace, Name);
    {_, Type} when is_atom(Type) ->
      %% this is a primitive type field, such as int8, string, bytes etc.
      Type;
    {_, {array, Type}} ->
      %% only primitive types possible here
      true = ?IS_KAFKA_PRIMITIVE(Type),
      {array, Type}
  end;
field_type(Namespace, {array, Name}, Def) ->
  {array, field_type(Namespace, Name, Def)}.

%% "foo_responses" -> "foo_response".
%% Very, very naive and dangerous implementation!
singular(Plural) -> string:strip(Plural, right, $s).

%% "FooBarV1" -> "foo_bar_v1"
underscorize([H | T]) ->
    [ string:to_lower(H) |
      lists:flatmap(
        fun(C) ->
            case $A =< C andalso C =< $Z  of
               true -> [$_, string:to_lower(C)];
               false -> [C]
            end
        end, T)].

%% generate include/kpro.hrl
gen_header_file(Records) ->
  Blocks =
    [ "%% generated code, do not edit!"
    , ""
    , "-ifndef(kpro_hrl)."
    , "-define(kpro_hrl, true)."
    , ""
    , "-include(\"kpro_common.hrl\")."
    , ""
    , gen_records(Records)
    , gen_types(Records)
    , ""
    , "-endif.\n"
    ],
  IoData = infix(Blocks, "\n"),
  Filename = filename:join(["..", "include", "kpro.hrl"]),
  ok = file:write_file(Filename, IoData).

gen_types(Records) -> lists:map(fun gen_type/1, Records).

gen_type({Name, {one_of, Refs}}) ->
  RecName = atom_to_list(Name),
  Header = "-type " ++ RecName ++ "() :: ",
  Sep = "\n" ++ lists:duplicate(length(Header) - 2, $\s) ++ "| ",
  [ Header,
    infix([atom_to_list(Ref) ++ "()" || Ref <- Refs], Sep),
    ".\n"
  ];
gen_type({Name, _Fields}) ->
  RecName = atom_to_list(Name),
  ["-type ", RecName, "() :: #", RecName, "{}.\n"].

gen_records(Records) -> lists:map(fun gen_record/1, Records).

gen_record({_Name, {one_of, _Refs}}) ->
  [];
gen_record({Name, Fields}) ->
  {FieldLines, TypeRefs} = gen_record_fields(Fields, [], []),
  ["-record(", atom_to_list(Name), ",\n",
   "        { ",
              infix(FieldLines, "        , "),
   "        }).\n\n",
   TypeRefs
  ].

gen_record_fields([], FieldLines, TypeRefs) ->
  {lists:reverse(FieldLines), TypeRefs};
gen_record_fields([{Name, Type} | Fields], FieldLines, TypeRefs) ->
  FieldName = atom_to_list(Name),
  FieldType = gen_field_type(list_to_atom(FieldName), Type),
  FieldLine = iolist_to_binary([ FieldName, " :: ", FieldType, "\n" ]),
  gen_record_fields(Fields, [FieldLine | FieldLines], TypeRefs).

%% generate special pre-defined types.
%% all 'errorCode' fields should have error_code() spec
%% use 'any()' spec for all embeded 'bytes' fields
gen_field_type(error_code, _)     -> "kpro:error_code()";
gen_field_type(protocol_metadata, bytes) -> "any()";
gen_field_type(member_assignment, bytes) -> "any()";
gen_field_type(key, bytes) -> "kpro:kafka_key()";
gen_field_type(value, bytes) -> "kpro:kafka_value()";
gen_field_type(_FieldName, Type) ->
  gen_field_type(Type).

gen_field_type(boolean)-> "boolean()";
gen_field_type(int8)   -> "kpro:int8()";
gen_field_type(int16)  -> "kpro:int16()";
gen_field_type(int32)  -> "kpro:int32()";
gen_field_type(int64)  -> "kpro:int64()";
gen_field_type(string) -> "kpro:str()";
gen_field_type(nullable_string) -> "kpro:str()";
gen_field_type(bytes)  -> "binary()";
gen_field_type({array, Name}) ->
  "[" ++ gen_field_type(Name) ++ "]";
gen_field_type(Name) when is_atom(Name) ->
  atom_to_list(Name) ++ "()".

%% generate src/kpro_records.erl
gen_records_module(Records) ->
  Blocks =
    [ "%% generated code, do not edit!"
    , ""
    , "-module(kpro_records)."
    , "-export([fields/1])."
    , "-include(\"kpro.hrl\")."
    , ""
    , [ [gen_record_fields_clause(Record) || Record <- Records]
      , "fields(_Unknown) -> false."
      ]
    ],
  IoData = infix(Blocks, "\n"),
  Filename = filename:join(["..", "src", "kpro_records.erl"]),
  ok = file:write_file(Filename, IoData),
  ok = erl_tidy:file(Filename).

%% fields(#kpro_xyz{} = R) ->
%%  record_info(fields, kpro_xyz);
gen_record_fields_clause({_RecordName, {one_of, _Fields}}) -> [];
gen_record_fields_clause({RecordName, _Fields}) ->
  Name = atom_to_list(RecordName),
  [ "fields(", Name, ") ->\n"
  , "  record_info(fields, ", Name, ");\n"
  ].


% src/kpro_structs.erl
gen_marshaller(Records) ->
  Filename = filename:join(["..", "src", "kpro_structs.erl"]),
  Header0 =
    [ "%% generated code, do not edit!"
    , "-module(kpro_structs)."
    , "-export([encode/1])."
    , "-export([decode/2])."
    , "-include(\"kpro.hrl\")."
    ],
  IoData =
    [ infix(Header0, "\n")
    , "\n"
    , gen_clauses(encoder, Records)
    , "\n"
    , gen_clauses(decoder, Records)
    , "\n"
    , "enc(X) -> kpro:encode(X).\n"
    , "\n"
    ],
  ok = file:write_file(Filename, IoData),
  ok = erl_tidy:file(Filename),
  ok.

all_requests() ->
  lists:flatten(
    lists:map(
      fun(ApiKey) -> ?API_KEY_TO_REQ(ApiKey) end, ?ALL_API_KEYS)).

all_responses() ->
  lists:map(fun(ApiKey) -> ?API_KEY_TO_RSP(ApiKey) end, ?ALL_API_KEYS).

gen_clauses(EncDec, Records) ->
  Names = case EncDec of
            encoder -> all_requests();
            decoder -> all_responses()
          end,
  Clauses0 = gen_clauses(EncDec, Names, Records),
  Clauses1 = lists:flatten(Clauses0),
  Clauses  = lists:filter(fun(I) -> I =/= <<>> end, Clauses1),
  [infix(Clauses, ";\n"), "."].

gen_clauses(_EncDec, [], _Records) -> [];
gen_clauses(EncDec, [Name | Rest], Records) ->
  Clauses = gen_clauses(EncDec, Name, Records),
  [Clauses | gen_clauses(EncDec, Rest, Records)];
gen_clauses(EncDec, Name, Records) when is_atom(Name) ->
  case get({EncDec, Name}) of
    undefined ->
      put({EncDec, Name}, generated),
      Fields =
        try
          {_, X} = lists:keyfind(Name, 1, Records),
          X
        catch _:_ ->
            erlang:exit({not_found, Name, erlang:get_stacktrace()})
        end,
      IoData = gen_clause(EncDec, Name, Fields),
      RefNames = get_ref_names(Fields),
      [ iolist_to_binary(IoData)
      , lists:map(fun(N) -> gen_clauses(EncDec, N, Records) end, RefNames)];
    generated ->
      []
  end.

get_ref_names([]) -> [];
get_ref_names([{_N, {array, T}} | Rest]) when not ?IS_KAFKA_PRIMITIVE(T) ->
  [T | get_ref_names(Rest)];
get_ref_names([{_N, T} | Rest]) when is_atom(T), not ?IS_KAFKA_PRIMITIVE(T) ->
  [T | get_ref_names(Rest)];
get_ref_names([_ | Rest]) ->
  get_ref_names(Rest).

%% generate a encode/decode function clause for one structure.
%%
%% encoder example:
%%
%% encode(Record) ->
%%  [ enc(Field1Type, Record#recordMame.field1Name),
%%    enc(Field1Type, Record#recordMame.field1Name),
%%    ...]
%%
%% decoder example:
%%
%% decode(RecordName, Bin) ->
%%    kpro:decode_fields(RecordName, Fields, Bin).
%%
gen_clause(encoder, Name, Fields) ->
  VariableName = case Fields of
                   [] -> "";
                   _  -> " = R"
                 end,
  RecName = atom_to_list(Name),
  FieldPrefix = "R#" ++ RecName ++ ".",
  [ "encode(" ++ record_pattern(Name) ++ VariableName ++ ")->\n"
  , "  ["
  ,      infix(gen_field_encoders(FieldPrefix, Fields), ",\n   ")
  , "\n"
  , "  ]"
  ];
gen_clause(decoder, Name, Fields) ->
  [ "decode(", atom_to_list(Name) ,", Bin) ->\n"
  , "Fields = ", gen_field_types(Fields), ","
  , "kpro:decode_fields(", atom_to_list(Name), ", Fields, Bin)"
  ].

gen_field_encoders(_Prefix, []) -> [];
gen_field_encoders(Prefix, [{FieldName, FieldType} | Fields]) ->
  FieldV_code = Prefix ++ atom_to_list(FieldName),
  [ bin(["enc(", encode_arg_code(FieldType, FieldV_code), ")"])
  | gen_field_encoders(Prefix, Fields)].

encode_arg_code(T, V) when ?IS_KAFKA_PRIMITIVE(T) ->
  ["{", atom_to_list(T), ", ", V, "}"];
encode_arg_code({array, T}, V) when ?IS_KAFKA_PRIMITIVE(T) ->
  ["{{array,", atom_to_list(T), "}, ", V, "}"];
encode_arg_code({array, _T}, V) ->
  ["{array, ", V, "}"];
encode_arg_code(_T, V) ->
  V.

record_pattern(Name) ->
  "#" ++ atom_to_list(Name) ++ "{}".

bin(IoList) -> iolist_to_binary(IoList).

gen_field_types(Fields) ->
  io_lib:format("~p", [Fields]).

%% common utils

infix([], _Sep) -> [];
infix([Str], _Sep) -> [Str];
infix([H | T], Sep) -> [H, Sep | infix(T, Sep)].


%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
