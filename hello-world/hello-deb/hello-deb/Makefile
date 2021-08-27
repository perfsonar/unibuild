#
# Makefile for Unibuild Hello
#

default: build

build:
	@echo Nothing to do here.

install:
ifndef BINDIR
	@echo "BINDIR is not defined."
	@false
endif
	install -m 555 hello-deb "$(BINDIR)"

clean:
	rm -rf $(TO_CLEAN) *~
