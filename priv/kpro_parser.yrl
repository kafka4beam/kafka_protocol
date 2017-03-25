Nonterminals bnf groups defs def one_of fields field
  new_line new_line_and_indent some_empty_lines.
Terminals name prim '[' ']' '|' '=>' one_new_line one_new_line_and_indent.
Rootsymbol bnf.

bnf -> some_empty_lines groups : '$2'.

groups -> defs : ['$1'].
groups -> defs groups : ['$1' | '$2'].

defs -> def new_line : ['$1'].
defs -> def new_line_and_indent defs : ['$1' | '$3'].

def -> name '=>' : {v('$1'), []}.
def -> name '=>' prim : {v('$1'), v('$3')}.
def -> name '=>' '[' prim ']' : {v('$1'), {array, v('$4')}}.
def -> name '=>' one_of : {v('$1'), {one_of, '$3'}}.
def -> name '=>' fields : {v('$1'), '$3'}.

one_of -> name '|' name : [v('$1'), v('$3')].
one_of -> name '|' one_of : [v('$1') | '$3'].

fields -> field : ['$1'].
fields -> field fields : ['$1' | '$2'].

field -> name : v('$1').
field -> '[' name ']' : {array, v('$2')}.


some_empty_lines -> '$empty'.
some_empty_lines -> new_line.
some_empty_lines -> new_line_and_indent.

new_line -> some_empty_lines one_new_line.
new_line_and_indent -> some_empty_lines one_new_line_and_indent.

Erlang code.

v({_Tag, _Line, Value}) -> Value.
