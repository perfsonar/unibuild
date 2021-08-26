#
# Makefile for unibuild
#

default: build

build:
	@echo Nothing to do here.



install:
ifndef LIBEXECDIR
	@echo No LIBEXECDIR defined.
	false
endif
	mkdir -p $(LIBEXECDIR)
	cp -r libexec/* $(LIBEXECDIR)
ifndef LIBEXECINSTALLEDDIR
	@echo No LIBEXECINSTALLEDDIR defined.
	false
endif
ifndef BINDIR
	@echo No BINDIR defined.
	false
endif
	mkdir -p $(BINDIR)
	ln -s $(LIBEXECINSTALLEDDIR)/unibuild $(BINDIR)
ifndef DOCDIR
	@echo No DOCDIR defined.
	false
endif
	mkdir -p $(DOCDIR)
	install -m 444 README.md $(DOCDIR)


clean:
	rm -f *~
