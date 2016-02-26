PROJECT = kpro
PROJECT_DESCRIPTION = Kafka message wire format encode/decode library
PROJECT_VERSION = 0.1.0

COVER = true

EUNIT_OPTS = verbose
ERLC_OPTS = -Werror +warn_unused_vars +warn_shadow_vars +warn_unused_import +warn_obsolete_guard +debug_info
CT_OPTS = -ct_use_short_names true

GEN_CODE = include/kpro.hrl src/kpro_structs.erl

app:: gen-code
clean:: gen-clean

include erlang.mk

.PHONY: gen-code gen-clean

$(GEN_CODE):: include/kpro_common.hrl priv/kpro_gen.sh priv/kpro_gen.escript priv/kafka.bnf priv/kpro_scanner.xrl priv/kpro_parser.yrl
	priv/kpro_gen.escript

gen-code: $(GEN_CODE)
	$(verbose) :

gen-clean:
	rm -f $(GEN_CODE) src/kpro_structs.erl.bak

