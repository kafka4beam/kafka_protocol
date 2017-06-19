#!/usr/bin/env escript
%% -*- erlang -*-

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
%%   src/kpro_schema.erl

-mode(compile).

-include("../include/kpro_private.hrl").

main(_Args) ->
  ok = file:set_cwd(this_dir()),
  {ok, _} = leex:file(kpro_scanner),
  {ok, _} = compile:file(kpro_scanner, [report_errors]),
  {ok, _} = yecc:file(kpro_parser),
  {ok, _} = compile:file(kpro_parser, [report_errors]),
  {ok, DefGroups} = kpro_parser:file("kafka.bnf"),
  ExpandedTypes = [I || I <- lists:map(fun expand/1, DefGroups), is_tuple(I)],
  GrouppedTypes = group_per_name(ExpandedTypes, []),
  ok = generate_schema_module(GrouppedTypes).

-define(SCHEMA_MODULE_HEADER,"%% generated code, do not edit!
-module(kpro_schema).
-export([get/2]).
").

generate_schema_module(GrouppedTypes) ->
  Filename = filename:join(["..", "src", "kpro_schema.erl"]),
  Clauses = lists:flatmap(fun generate_schema_clauses/1, GrouppedTypes),
  IoData =
    [?SCHEMA_MODULE_HEADER,
     "\n",
     infix(Clauses, ";\n"),
     ".\n\n"
    ],
  file:write_file(Filename, IoData).

generate_schema_clauses({Name, VersionedFields0}) ->
  VersionedFields = lists:keysort(1, VersionedFields0),
  generate_schema_clauses(Name, merge_versions(VersionedFields)).

generate_schema_clauses(_Name, []) -> [];
generate_schema_clauses(Name, [{Versions, Fields} | Rest]) ->
  Head =
    case Versions of
      V when is_integer(V) ->
        ["get(", Name, ", ", integer_to_list(V), ") ->"];
      [V | Vs] ->
        MinV = integer_to_list(V),
        MaxV = integer_to_list(lists:last(Vs)),
        ["get(", Name, ", V) when V >= ", MinV, ", V =< ", MaxV, " ->"]
    end,
  Body = io_lib:format("  ~p", [Fields]),
  [ iolist_to_binary([Head, "\n", Body])
  | generate_schema_clauses(Name, Rest)
  ].

group_per_name([], Acc) -> Acc;
group_per_name([ExpandedType | Rest], Acc) ->
  {Name, Version, Fields} = split_name_version(ExpandedType),
  AccumulatedVersions1 =
    case lists:keyfind(Name, 1, Acc) of
      false ->
        [];
      {_, AccumulatedVersions0} ->
        AccumulatedVersions0
    end,
  AccumulatedVersions = [{Version, Fields} | AccumulatedVersions1],
  NewAcc = lists:keystore(Name, 1, Acc, {Name, AccumulatedVersions}),
  group_per_name(Rest, NewAcc).

merge_versions([]) -> [];
merge_versions([_] = L) -> L;
merge_versions([{V1, Fields1}, {V2, Fields2} | Rest]) ->
  case Fields1 =:= Fields2 of
    true ->
      Versions = lists:flatten([V1, V2]),
      merge_versions([{Versions, Fields1} | Rest]);
    false ->
      [{V1, Fields1} | merge_versions([{V2, Fields2} | Rest])]
  end.

split_name_version({Tag, Fields}) ->
  [Vsn, $v, $_ | NameReversed] =
    lists:reverse(underscorize(atom_to_list(Tag))),
  Name = lists:reverse(NameReversed),
  Version = Vsn - $0,
  {Name, Version, Fields}.

expand([{Tag, Fields} | Refs]) ->
  {Tag, expand_fields(Fields, Refs)}.

expand_fields([], _Refs) -> [];
expand_fields([Name | Rest], Refs) when is_atom(Name) ->
  {Name, Type0} = lists:keyfind(Name, 1, Refs),
  Type = expand_type(Type0, Refs),
  [{Name, Type} | expand_fields(Rest, Refs)];
expand_fields([{array, Name} | Rest], Refs) ->
  {Name, Type0} = lists:keyfind(Name, 1, Refs),
  Type = expand_type(Type0, Refs),
  [{Name, {array, Type}} | expand_fields(Rest, Refs)].

expand_type(Type, _Refs) when ?IS_KAFKA_PRIMITIVE(Type) ->
  Type;
expand_type(Fields, Refs) when is_list(Fields) ->
  expand_fields(Fields, Refs).

this_dir() ->
  ThisScript = escript:script_name(),
  filename:dirname(ThisScript).

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

infix([], _Sep) -> [];
infix([Str], _Sep) -> [Str];
infix([H | T], Sep) -> [H, Sep | infix(T, Sep)].

%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
