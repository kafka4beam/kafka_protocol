Definitions.

Rules.

% longest match wins, first match if both of the same length. "prims" are all caps.
ARRAY : {token, {'ARRAY', TokenLine}}.
[A-Z][_0-9A-Z]* : {token, {prim, TokenLine, list_to_atom(string:to_lower(TokenChars))}}.
[A-Za-z][_0-9a-zA-Z]* : {token, {name, TokenLine, list_to_atom(TokenChars)}}.
=> : {token, {'=>', TokenLine}}.
\[ : {token, {'[', TokenLine}}.
\] : {token, {']', TokenLine}}.
\( : {token, {'(', TokenLine}}.
\) : {token, {')', TokenLine}}.
\| : {token, {'|', TokenLine}}.
\n : {token, {one_new_line, TokenLine}}.
\n\s+ : {token, {one_new_line_and_indent, TokenLine}}.
\s : skip_token.
#.* : skip_token.

Erlang code.
