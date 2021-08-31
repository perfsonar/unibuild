#
# Makefile for Unibuild Hello World
#

default: build

REPO=unibuild-repo
TO_CLEAN += $(REPO)

build:
	unibuild
	mkdir -p $(REPO)
	unibuild gather $(REPO)

clean:
	unibuild make clean
	rm -rf $(TO_CLEAN) *~
