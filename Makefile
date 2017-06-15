
all: compile

rebar ?= $(shell which rebar3)
rebar_cmd = $(rebar) $(profile:%=as %)

GEN_INPUT = include/*.hrl priv/kpro_gen.escript priv/kafka.bnf priv/kpro_scanner.xrl priv/kpro_parser.yrl
GEN_CODE = src/kpro_schema.erl

.PHONY: gen-code gen-clean kafka-bnf

kafka-bnf:
	@cd priv/kafka_protocol_bnf && gradle run

$(GEN_CODE):: $(GEN_INPUT)
	priv/kpro_gen.escript

$(PROJECT).d:: $(GEN_CODE)

gen-code: $(GEN_CODE)
	$(verbose) :

gen-clean:
	@rm -f priv/*.beam priv/*.erl

.PHONY: clean
clean: gen-clean
	@$(rebar_cmd) clean

.PHONY: xref
xref:
	@$(rebar_cmd) xref

.PHONY: eunit
eunit:
	@$(rebar_cmd) eunit -v

.PHONY: compile
compile:
	@$(rebar_cmd) compile

.PHONY: distclean
distclean: clean
	@rm -rf _build deps

.PHONY: edoc
edoc: profile=edown
edoc:
	@$(rebar_cmd) edoc

.PHONY: dialyze
dialyze: compile
	@$(rebar_cmd) dialyzer

.PHONY: hex-publish
hex-publish: distclean
	$(verbose) rebar3 hex publish

