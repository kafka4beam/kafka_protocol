PROJECT = kpro
PROJECT_DESCRIPTION = Kafka message wire format encod / decode library
PROJECT_VERSION = 0.1.0

TEST_DEPS = meck proper

COVER = true

EUNIT_OPTS = verbose
ERLC_OPTS = -Werror +warn_unused_vars +warn_shadow_vars +warn_unused_import +warn_obsolete_guard +debug_info
CT_OPTS = -ct_use_short_names true

include erlang.mk

include/kpro.hrl: priv/kpro_gen.sh priv/kpro_gen.escript priv/spec.bnf priv/kpro_scanner.xrl priv/kpro_parser.yrl include/kpro_common.hrl
	priv/kpro_gen.sh

ERL_LIBS := $(ERL_LIBS):$(CURDIR)

