#
# Makefile for Unibuild
#

ifdef RELEASE
UNIBUILD_OPTS += --release
endif

UNIBUILD=./unibuild/unibuild/libexec/unibuild $(UNIBUILD_OPTS)

ifdef START
UNIBUILD_BUILD_OPTS += --start $(START)
endif

ifdef STOP
UNIBUILD_BUILD_OPTS += --stop $(STOP)
endif

BUILD_LOG=unibuild-log
TO_CLEAN += $(BUILD_LOG)

REPO=unibuild-repo
TO_CLEAN += $(REPO)

default: $(REPO)

build:
	(((( \
		$(UNIBUILD) build $(UNIBUILD_BUILD_OPTS) ; \
		echo $$? >&3 \
	) \
	| tee $(BUILD_LOG) >&4) 3>&1) \
	| (read XS; exit $$XS) \
	) 4>&1
	$(UNIBUILD)


release:
	RELEASE=1 $(MAKE)



$(REPO): build
	(((( \
		mkdir -p $@ ; \
		$(UNIBUILD) gather $$(readlink -e '$@') ;\
		echo $$? >&3 \
	) \
	| tee -a $(BUILD_LOG) >&4) 3>&1) \
	| (read XS; exit $$XS) \
	) 4>&1




clean:
	$(UNIBUILD) $@
	rm -rf $(TO_CLEAN)


todo:
	fgrep -r TODO .
