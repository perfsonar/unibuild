#
# Makefile for Unibuild
#

default:  build

UNIBUILD=./unibuild/unibuild/libexec/unibuild

BUILD_LOG=LOG
TO_CLEAN += $(BUILD_LOG)

build:
	(((( \
		$(UNIBUILD) ; \
		echo $$? >&3 \
	) \
	| tee $(BUILD_LOG) >&4) 3>&1) \
	| (read XS; exit $$XS) \
	) 4>&1
	$(UNIBUILD)


clean:
	$(UNIBUILD) make $@
	rm -rf $(TO_CLEAN)
