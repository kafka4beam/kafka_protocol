KAFKA_VERSION ?= 1.1
all: compile

rebar ?= $(shell which rebar3)
rebar_cmd = $(rebar) $(profile:%=as %)

GEN_INPUT = include/*.hrl priv/kpro_gen.escript priv/kafka.bnf priv/kpro_scanner.xrl priv/kpro_parser.yrl
GEN_CODE = src/kpro_schema.erl

# results of this target are to be committed in this repo
.PHONY: kafka-bnf
kafka-bnf:
	@cd priv/kafka_protocol_bnf && gradle run
	@cat priv/kafka.bnf | grep "#.*ApiKey" | awk '{print "{"$$2" "$$3"}."}' | sed -r 's/([A-Z])/_\L\1/g' | sed 's/{_/{/' | sort -hk2 > priv/api-keys.eterm

$(GEN_CODE): $(GEN_INPUT)
	@priv/kpro_gen.escript

$(PROJECT).d: $(GEN_CODE)

.PHONY: gen-code
gen-code: $(GEN_CODE)
	@$(verbose) :

.PHONY: gen-clean
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
	@$(rebar_cmd) eunit -v --cover_export_name $(KAFKA_VERSION)

.PHONY: compile
compile:
	@$(rebar_cmd) compile

.PHONY: distclean
distclean: clean
	@rm -rf _build deps
	@rm -f rebar.lock

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

.PHONY: testbed
testbed:
	@$(verbose) ./scripts/setup-testbed.sh $(KAFKA_VERSION)

.PHONY: cover
cover:
	@rebar3 cover -v
