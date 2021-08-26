#
# Makefile for Unibuild
#

default:  build

UNIBUILD=./unibuild/unibuild/unibuild

build:
	$(UNIBUILD)


clean:
	$(UNIBUILD) make $@
	rm -rf $(TO_CLEAN)
