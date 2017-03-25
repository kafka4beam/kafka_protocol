Definitions.

Rules.

[A-Za-z][A-Za-z0-9]* : {token, name_or_prim(TokenChars, TokenLine)}.
=> : {token, {'=>', TokenLine}}.
\[ : {token, {'[', TokenLine}}.
\] : {token, {']', TokenLine}}.
\| : {token, {'|', TokenLine}}.
\s : skip_token.
\n : skip_token.
#.* : skip_token.

Erlang code.

-export([file/1]).

file(Filename) ->
  {ok, Fd} = file:open(Filename, [read]),
  try
    read_lines(Fd, [], [], 1)
  after
    file:close(Fd)
  end.

read_lines(Fd, Def, Defs, LineNr) ->
  case file:read_line(Fd) of
    eof ->
      lists:reverse([lists:reverse(Def) | Defs]);
    {ok, Line} ->
      {ok, Tokens, _LineNum} = string(Line, LineNr),
      case is_new_def(Def, Line) of
        true ->
          NewDef = lists:reverse(Def),
          read_lines(Fd, [Tokens], [NewDef | Defs], LineNr+1);
        false ->
          NewDef = add_tokens(Tokens, Def),
          read_lines(Fd, NewDef, Defs, LineNr+1)
      end
  end.

is_new_def([_|_], [C | _]) -> C >= $A andalso C =< $Z;
is_new_def(_, _)           -> false.

add_tokens([], Def)             -> Def;
add_tokens([_|_] = Tokens, Def) -> [Tokens | Def].

is_lowercase(C) when C >= $a, C =< $z -> true;
is_lowercase(_) -> false.

name_or_prim(TokenChars, TokenLine) ->
  % has lowercase letters?
  case lists:any(fun is_lowercase/1, TokenChars) of
  true ->
    {name, TokenLine, list_to_atom(TokenChars)};
  false ->
    {prim, TokenLine, list_to_atom(string:to_lower(TokenChars))}
  end.
