#
# Makefile for Unibuild Hello World
#
# Note that this requires an installed, functioning Unibuild.
#

ifdef RELEASE
UNIBUILD_OPTS += --release
endif

default: build

REPO=unibuild-repo
TO_CLEAN += $(REPO)

build:
	unibuild $(UNIBUILD_OPTS)

clean:
	unibuild $(UNIBUILD_OPTS) make clean
	rm -rf $(TO_CLEAN) *~
