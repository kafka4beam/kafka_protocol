PROJECT = kafka_protocol
PROJECT_DESCRIPTION = Kafka protocol erlang library
PROJECT_VERSION = 0.7.0

DEPS = snappyer

dep_snappyer_commit = 1.1.3-1.0.2

COVER = true

EUNIT_OPTS = verbose
ERLC_OPTS = -Werror +warn_unused_vars +warn_shadow_vars +warn_unused_import +warn_obsolete_guard +debug_info
CT_OPTS = -ct_use_short_names true

GEN_INPUT = include/kpro_common.hrl priv/kpro_gen.escript priv/kafka.bnf priv/kpro_scanner.xrl priv/kpro_parser.yrl
GEN_CODE = include/kpro.hrl src/kpro_structs.erl src/kpro_records.erl

app:: gen-code
clean:: gen-clean

include erlang.mk

.PHONY: gen-code gen-clean

$(GEN_CODE):: $(GEN_INPUT)
	priv/kpro_gen.escript

$(PROJECT).d:: $(GEN_CODE)

gen-code: $(GEN_CODE)
	$(verbose) :

gen-clean:
	rm -f $(GEN_CODE) src/kpro_structs.erl.bak

