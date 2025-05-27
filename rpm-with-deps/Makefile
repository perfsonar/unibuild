#
# Makefile for rpm-with-deps RPM
#
# This package is built by hand because make-generic-package depends
# on it (RedHat-derived systems only).
#

SPEC_FILE := ./rpm-with-deps/unibuild-packaging/rpm/rpm-with-deps.spec

NAME=$(shell grep -F Name: $(SPEC_FILE) | awk '{ print $$2 }')
VERSION=$(shell grep -F Version: $(SPEC_FILE) | awk '{ print $$2 }')

RPMDIR=$(shell pwd)/BUILD
BUILDROOT=$(RPMDIR)/BUILDROOT

# Figure out what needs to be run to get root.
ifeq ($(shell id -u),0)
  RUN_AS_ROOT :=
else
  RUN_AS_ROOT := sudo
endif


# Figure out what this system has for installing packages.
ifneq ($(shell command -v dnf),)
  PACKAGE_INSTALLER := dnf
else
  PACKAGE_INSTALLER := yum
endif


default: build


.rpmmacros:
	rm -f $@
	echo %_topdir $(RPMDIR) > .rpmmacros
TO_CLEAN += .rpmmacros


FULLNAME=$(NAME)-$(VERSION)
TARBALL=$(FULLNAME).tar.gz

$(TARBALL):
	rm -f $@ $(FULLNAME)
	cp -r $(NAME) $(FULLNAME)
	tar czf $@ $(NAME) $(FULLNAME)
	rm -rf $(FULLNAME)
TO_CLEAN += $(TARBALL) $(FULLNAME)


$(RPMDIR): $(TARBALL)
	rpm -q rpm-build || $(RUN_AS_ROOT) $(PACKAGE_INSTALLER) -y install rpm-build
	mkdir -p \
		$(RPMDIR)/BUILD \
		$(RPMDIR)/RPMS \
		$(RPMDIR)/SOURCES \
		$(RPMDIR)/SPECS \
		$(RPMDIR)/SRPMS \
		$(BUILDROOT)
	cp -pf $(TARBALL) $(RPMDIR)/SOURCES
	cp -pf $(SPEC_FILE) $(RPMDIR)/SPECS
TO_CLEAN += $(RPMDIR) $(BUILDROOT)

LOG=log
build: .rpmmacros $(TARBALL) $(RPMDIR)
	HOME=$(shell pwd) rpmbuild -v -ba --buildroot $(BUILDROOT) $(SPEC_FILE) 2>&1 \
                | tee $(LOG)
TO_CLEAN += $(LOG)


srpm: .rpmmacros $(TARBALL) $(RPMDIR)
	HOME=$(shell pwd) rpmbuild -v -bs --buildroot $(BUILDROOT) $(SPEC_FILE) 2>&1
	rm -f *.src.rpm
	find $(BUILD_DIR) -name '*.src.rpm' | xargs -I{} cp -pf {} .
TO_CLEAN += *.src.rpm



install: build
	find $(RPMDIR)/RPMS -name "*.rpm" | xargs $(RUN_AS_ROOT) rpm -Uvh --force


# Copy the products to a destination named by PRODUCTS_DEST
install-products:
ifndef PRODUCTS_DEST
	@printf "\nERROR: No PRODUCTS_DEST defined for $@.\n\n"
	@false
endif
	@if [ ! -d "$(PRODUCTS_DEST)" ] ; then \
	    printf "\nERROR: $(PRODUCTS_DEST) is not a directory.\n\n" ; \
	    false ; \
	fi
	find "$(RPMDIR)" -name '*.rpm' -exec cp {} "$(PRODUCTS_DEST)" \;



uninstall:
	$(RUN_AS_ROOT) $(PACKAGE_INSTALLER) -y remove $(NAME) || true


clean:
	rm -rf $(TO_CLEAN)
	find . -name '*~' | xargs -r rm -f
