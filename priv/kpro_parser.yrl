Nonterminals def one_of fields field.
Terminals name prim '[' ']' '|' '=>'.
Rootsymbol def.

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

Erlang code.

v({_Tag, _Line, Value}) -> Value.

