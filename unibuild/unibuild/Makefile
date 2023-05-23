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
ifndef BINDIR
	@echo No BINDIR defined.
	false
endif
ifndef LIBEXECBINDIR
	@echo No LIBEXECBINDIR defined.
	false
endif
ifndef LIBEXECINSTALLEDBINDIR
	@echo No LIBEXECINSTALLEDBINDIR defined.
	false
endif
	mkdir -p $(BINDIR)
	ln -s $(LIBEXECINSTALLEDBINDIR)/unibuild $(BINDIR)/unibuild
	ln -s $(LIBEXECINSTALLEDBINDIR)/multibuild $(BINDIR)/multibuild
ifndef DOCDIR
	@echo No DOCDIR defined.
	false
endif
	mkdir -p $(DOCDIR)
	install -m 444 README.md $(DOCDIR)


clean:
	rm -rf $(TO_CLEAN) *~
