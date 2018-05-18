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

main(_Args) ->
  ok = file:set_cwd(this_dir()),
  {ok, _} = leex:file(kpro_scanner),
  {ok, _} = compile:file(kpro_scanner, [report_errors]),
  {ok, _} = yecc:file(kpro_parser),
  {ok, _} = compile:file(kpro_parser, [report_errors]),
  {ok, DefGroups} = kpro_parser:file("kafka.bnf"),
  ExpandedTypes = [I || I <- lists:map(fun expand/1, DefGroups), is_tuple(I)],
  GroupedTypes = group_per_name(ExpandedTypes, []),
  ok = generate_ec_hrl_file(),
  ok = generate_schema_module(GroupedTypes).

-define(SCHEMA_MODULE_HEADER,"%% generated code, do not edit!
-module(kpro_schema).
-export([all_apis/0, vsn_range/1, api_key/1, req/2, rsp/2, ec/1]).
").

generate_schema_module(GroupedTypes) ->
  Filename = filename:join(["..", "src", "kpro_schema.erl"]),
  IoData =
    [?SCHEMA_MODULE_HEADER, "\n",
     generate_all_apis_fun(GroupedTypes),
     generate_version_range_clauses(GroupedTypes),
     generate_api_key_clauses(),
     generate_req_rsp_clauses(GroupedTypes),
     generate_ec_clauses()
    ],
  file:write_file(Filename, IoData).

generate_req_rsp_clauses(GroupedTypes0) ->
  GroupedTypes =
    lists:map(fun({N, Types0}) ->
                  Types = lists:keysort(1, Types0),
                  {N, merge_versions(Types)}
              end, GroupedTypes0),
  ReqClauses = lists:flatmap(fun generate_req_clauses/1, GroupedTypes),
  RspClauses = lists:flatmap(fun generate_rsp_clauses/1, GroupedTypes),
  [infix(ReqClauses, ";\n"), ".\n\n",
   infix(RspClauses, ";\n"), ".\n"
  ].

generate_api_key_clauses() ->
  {ok, Apis} = file:consult("api-keys.eterm"),
  Clauses =
    [ ["api_key(", atom_to_list(Name), ") -> ", integer_to_list(Id), ";\n",
       "api_key(", integer_to_list(Id), ") -> ", atom_to_list(Name), ";\n"
      ] || {Name, Id} <- Apis
    ],
  [Clauses, "api_key(API) -> erlang:error({not_supported, API}).\n\n"].

generate_all_apis_fun(GroupedTypes) ->
  F = fun({Name, _}, Acc) ->
          case split_name(Name) of
            {API, "req"} ->
              case lists:member(API, Acc) of
                true -> Acc;
                false -> [API | Acc]
              end;
            _ ->
              Acc
          end
      end,
  APIs = lists:foldr(F, [], GroupedTypes),
  ["all_apis() ->\n[", infix(APIs, ",\n"), "].\n\n"].

generate_version_range_clauses(GroupedTypes) ->
  F = fun({Name, VersionedFields}, Acc) ->
          case split_name(Name) of
            {API, "req"} ->
              Versions = [V || {V, _} <- VersionedFields],
              Min = integer_to_list(lists:min(Versions)),
              Max = integer_to_list(lists:max(Versions)),
              Clause = ["vsn_range(", API, ") -> {", Min, ", ", Max, "};\n"],
              [Clause | Acc];
            {_API, "rsp"} ->
              Acc
          end
      end,
  Clauses = lists:foldr(F, [], GroupedTypes),
  [Clauses, "vsn_range(_) -> false.\n\n"].

generate_req_clauses(PerNameTypes) ->
  generate_schema_clauses(PerNameTypes, "req").

generate_rsp_clauses(PerNameTypes) ->
  generate_schema_clauses(PerNameTypes, "rsp").

generate_schema_clauses({Name, VersionedFields}, ReqOrRsp) ->
  case split_name(Name) of
    {API, ReqOrRsp} -> generate_schema_clauses(ReqOrRsp ,API, VersionedFields);
    {_, _} -> []
  end.

generate_schema_clauses(_ReqOrRsp, _API, []) -> [];
generate_schema_clauses(ReqOrRsp, API, [{Versions, Fields} | Rest]) ->
  Head =
    case Versions of
      V when is_integer(V) ->
        [ReqOrRsp, "(", API, ", ",integer_to_list(V), ") ->"];
      [V | Vs] ->
        Min = integer_to_list(V),
        Max = integer_to_list(lists:last(Vs)),
        [ReqOrRsp, "(", API, ", V) ", "when V >= ", Min, ", V =< ", Max, " ->"]
    end,
  Body = io_lib:format("  ~p", [Fields]),
  [ iolist_to_binary([Head, "\n", Body])
  | generate_schema_clauses(ReqOrRsp, API, Rest)
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

split_name(Name) ->
  case lists:reverse(Name) of
    "tseuqer_" ++ API -> {lists:reverse(API), "req"};
    "esnopser_" ++ API -> {lists:reverse(API), "rsp"}
  end.

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

expand_type({array, Type}, Refs) ->
  %% Array of array
  {array, expand_type(Type, Refs)};
expand_type(Fields, Refs) when is_list(Fields) ->
  expand_fields(Fields, Refs);
expand_type(Type, _Refs) ->
  Type.

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

%% error-code decoder
generate_ec_clauses() ->
  {ok, Errors} = file:consult("error-codes.eterm"),
  DecodeClauses =
    lists:map(
      fun({Name, Code, _Retriable, _Desc}) ->
          ["ec(", integer_to_list(Code), ") -> ", string:to_lower(Name)]
      end, Errors),
  [infix(DecodeClauses, ";\n"), ".\n"].

generate_ec_hrl_file() ->
  {ok, Errors} = file:consult("error-codes.eterm"),
  Macros =
    lists:map(
      fun({Name, Code, _, _}) ->
          Lower = string:to_lower(Name),
          ["-define(", Lower, ",\n",
           "        ", Lower, "). % ", integer_to_list(Code), "\n"]
      end, Errors),
  Filename = filename:join(["..", "include", "kpro_error_codes.hrl"]),
  file:write_file(Filename, ["%% Generated code, do not edit!\n\n",
                             "-ifndef(KPRO_ERROR_CODES_HRL).\n",
                             "-define(KPRO_ERROR_CODES_HRL, true).\n\n",
                             Macros,
                             "\n-endif.\n"]).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
