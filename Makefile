#
# Makefile for Unibuild
#

UNIBUILD=./unibuild/unibuild/libexec/unibuild

ifdef START
UNIBUILD_OPTS += --start $(START)
endif

ifdef STOP
UNIBUILD_OPTS += --stop $(STOP)
endif

ifdef RELEASE
UNIBUILD_OPTS += --release 
endif

BUILD_LOG=unibuild-log
TO_CLEAN += $(BUILD_LOG)

REPO=unibuild-repo
TO_CLEAN += $(REPO)

default: $(REPO)

build:
	(((( \
		$(UNIBUILD) build $(UNIBUILD_OPTS) ; \
		echo $$? >&3 \
	) \
	| tee $(BUILD_LOG) >&4) 3>&1) \
	| (read XS; exit $$XS) \
	) 4>&1
	$(UNIBUILD)



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
	$(UNIBUILD) make $@
	make -C hello-world $@
	rm -rf $(TO_CLEAN)


todo:
	fgrep -r TODO .
