#!/bin/bash -e

THIS_DIR="$(dirname $(readlink -f $0))"

cd $THIS_DIR

erl -noshell -eval "leex:file(kpro_scanner), yecc:file(kpro_parser), halt(0)"

mkdir -p ../ebin

ERLC="erlc +debug_info"

$ERLC kpro_scanner.erl kpro_parser.erl

./kpro_gen.escript
