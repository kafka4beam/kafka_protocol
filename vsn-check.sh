#!/bin/bash -e

PROJECT_VERSION="$1"
SNAPPYER_VSN="$2"

APP_VSN=$(erl -noshell -eval '{ok, [{_,_,L}]} = file:consult("src/kafka_protocol.app.src"), {vsn, Vsn} = lists:keyfind(vsn, 1, L), io:format("~s", [Vsn]), halt(0).')

if [ "$PROJECT_VERSION" != "$APP_VSN" ]; then
  echo "version discrepancy, PROJECT_VERSION=$PROJECT_VERSION, APP_VSN=$APP_VSN"
  exit 1
fi

SNAPPYER_VSN_REBAR=$(erl -noshell -eval '{ok, Config} = file:consult("rebar.config"), [{snappyer, Vsn}] = proplists:get_value(deps, Config), io:format("~s", [Vsn]), halt(0).')

if [ "$SNAPPYER_VSN" != "$SNAPPYER_VSN_REBAR" ]; then
  echo "dependency snappyer version discrepancy, erlang.mk=$SNAPPYER_VSN, rebar=$SNAPPYER_VSN_REBAR"
  exit 2
fi

