#
# Makefile for Unibuild
#

default:  build

UNIBUILD=./unibuild/unibuild/unibuild

build:
	$(UNIBUILD)


clean:
	$(UNIBUILD) clean
	rm -rf $(TO_CLEAN)
