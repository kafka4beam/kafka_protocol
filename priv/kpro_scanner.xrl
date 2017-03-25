Definitions.

Rules.

[A-Z][0-9a-zA-Z]* : {token, {name, TokenLine, list_to_atom(TokenChars)}}.
[a-z][0-9a-zA-Z]* : {token, {prim, TokenLine, list_to_atom(TokenChars)}}.
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

