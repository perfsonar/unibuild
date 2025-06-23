#
# Generic Top-Level Unibuild Makefile
#

default:: build


BUILD_LOG=unibuild-log
UNIBUILD_REPO=unibuild-repo


ifdef START
UNIBUILD_OPTS += --start $(START)
endif
ifdef STOP
UNIBUILD_OPTS += --stop $(STOP)
endif
ifdef RELEASE
UNIBUILD_OPTS += --release
endif


# The shell command below does the equivalent of BASH's pipefail
# within the confines of POSIX.
# Source: https://unix.stackexchange.com/a/70675/15184
build::
	rm -rf $(BUILD_LOG) $(UNIBUILD_REPO)
	((( \
	(unibuild build $(UNIBUILD_OPTS); echo $$? >&3) \
	| tee $(BUILD_LOG) >&4) 3>&1) \
	| (read XS; exit $$XS) \
	) 4>&1
TO_CLEAN += $(BUILD_LOG)


uninstall::
	unibuild make --reverse $@


fresh:: uninstall build


clean::
	unibuild make $(UNIBUILD_OPTS) clean
	unibuild clean
	rm -rf $(TO_CLEAN)
	find . -name '*~' | xargs rm -f
