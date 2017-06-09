PROJECT = kafka_protocol
PROJECT_DESCRIPTION = Kafka protocol erlang library
PROJECT_VERSION = 1.0.0

EUNIT_OPTS = verbose
ERLC_OPTS = -Werror +warn_unused_vars +warn_shadow_vars +warn_unused_import +warn_obsolete_guard +debug_info
CT_OPTS = -ct_use_short_names true

ifeq ($(KAFKA_PROTOCOL_NO_SNAPPY),)
DEPS = snappyer
dep_snappyer_commit = 1.2.0
else
ERLC_OPTS += -DSNAPPY_DISABLED
endif

GEN_INPUT = include/kpro_common.hrl priv/kpro_gen.escript priv/kafka.bnf priv/kpro_scanner.xrl priv/kpro_parser.yrl
GEN_CODE = src/kpro_schema.erl

include erlang.mk

.PHONY: gen-code gen-clean kafka-bnf

kafka-bnf:
	@cd priv/kafka_protocol_bnf && gradle run

$(GEN_CODE):: $(GEN_INPUT)
	priv/kpro_gen.escript

$(PROJECT).d:: $(GEN_CODE)

gen-code: $(GEN_CODE)
	$(verbose) :

gen-clean:
	rm -f $(GEN_CODE) priv/*.beam priv/*.erl

vsn-check:
	$(verbose) ./vsn-check.sh $(PROJECT_VERSION) $(dep_snappyer_commit)

hex-publish: distclean
	$(verbose) rebar3 hex publish

