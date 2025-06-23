#
# Makefile for unibuild
#

default:
	@echo Nothing to do here.


COMMON := ./libexec/common
$(COMMON): $(COMMON).raw
ifndef VERSION
	@echo No VERSION defined.
	false
endif
	sed -e 's/__VERSION__/$(VERSION)/g' $< > $@
TO_CLEAN += $(COMMON)


install: $(COMMON)
ifndef LIBEXECDIR
	@echo No LIBEXECDIR defined.
	false
endif
	mkdir -p $(LIBEXECDIR)
	cp -r libexec/* $(LIBEXECDIR)
	rm -f $(LIBEXECDIR)/*.raw
ifndef LIBEXECINSTALLEDDIR
	@echo No LIBEXECINSTALLEDDIR defined.
	false
endif

ifndef INCLUDEDIR
	@echo No INCLUDEDIR defined.
	false
endif
	mkdir -p $(INCLUDEDIR)
	cp include/* $(INCLUDEDIR)
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
	rm -rf $(TO_CLEAN) *~
