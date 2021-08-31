#
# Makefile for Unibuild
#

UNIBUILD=./unibuild/unibuild/libexec/unibuild

BUILD_LOG=unibuild-log
TO_CLEAN += $(BUILD_LOG)

REPO=REPO
TO_CLEAN += $(REPO)

default: $(REPO)

build:
	(((( \
		$(UNIBUILD) ; \
		echo $$? >&3 \
	) \
	| tee $(BUILD_LOG) >&4) 3>&1) \
	| (read XS; exit $$XS) \
	) 4>&1
	$(UNIBUILD)



$(REPO): build
	(((( \
		mkdir -p $@ ; \
		unibuild gather $$(readlink -e '$@') ;\
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
