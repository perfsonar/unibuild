#
# Generic Makefile for Debian packagess
#

#
# NO USER-SERVICEABLE PARTS BELOW THIS LINE
#

ifndef UNIBUILD_PACKAGE_MAKE
$(error Include unibuild-package.make, not an environment-specific template.)
endif

SUDO := sudo

# Don't expect user interaction
SUDO += DEBIAN_FRONTEND=noninteractive

# Basic package information

# We don't care about rpm directories in anything we built
DEBIAN_DIR := $(shell find . -type d -name "deb" | egrep -ve '^./$(UNIBUILD_DIR)/')
ifeq "$(DEBIAN_DIR)" ""
$(error Unable to find Debian (deb) directory.)
endif
ifneq "$(words $(DEBIAN_DIR))" "1"
$(error Found more than one Debian (deb) directory.  There can be only one.)
endif
DEBIAN_DIR_PARENT := $(dir $(DEBIAN_DIR))


CONTROL := $(DEBIAN_DIR)/control

SOURCE := $(shell awk '-F: ' '$$1 == "Source" { print $$2 }' $(CONTROL))
ifeq "$(SOURCE)" ""
$(error Unable to find source name in $(CONTROL).)
endif


CHANGELOG := $(DEBIAN_DIR)/changelog
VERSION := $(shell egrep -e '^[^[:space:]]+[[:space:]]+' '$(CHANGELOG)' \
	| awk 'NR == 1 { print $$2 }' \
	| tr -d '()' \
	| sed -e 's/-.*$$//' \
	)
ifeq "$(VERSION)" ""
$(error Unable to find version in $(CHANGELOG).)
endif


# Build Directory and its Contents

# This is speculative; not all packages have a source tarball.
SOURCE_TARBALL := $(SOURCE)-$(VERSION).tar.gz

BUILD_UNPACK_DIR := $(BUILD_DIR)/$(SOURCE)
BUILD_DEBIAN_DIR := $(BUILD_UNPACK_DIR)/debian

$(BUILD_UNPACK_DIR):
	rm -rf '$@'
	mkdir -p '$@'
	cp -r '$(DEBIAN_DIR)' '$(BUILD_DEBIAN_DIR)'
	@set -e && if [ -e "$(SOURCE_TARBALL)" ] ; \
	then \
		printf "\nBuilding from tarball.\n\n" ; \
		(cd '$@' && tar xzf -) < '$(SOURCE_TARBALL)' ; \
		mv '$@/$(SOURCE)-$(VERSION)'/* '$@' ; \
		cp '$(SOURCE_TARBALL)' '$@' ; \
		(cd '$@' && mk-origtargz '$(SOURCE_TARBALL)') ; \
	elif [ -d "$(SOURCE)" ] ; \
	then \
		printf "\nBuilding from source directory $(SOURCE).\n\n" ; \
		(cd '$(SOURCE)' && tar cf - .) | (cd '$@' && tar xpf -) ; \
	elif [ "$(DEBIAN_DIR_PARENT)" != "$(dir $(BUILD_DIR))" ] ; \
	then \
		printf "\nBuilding from source directory $(DEBIAN_DIR_PARENT).\n\n" ; \
		(cd '$(DEBIAN_DIR_PARENT)' && tar cf - .) | (cd '$@' && tar xpf -) ; \
	else \
		printf "\nNo tarball or source directory.\n\n" ; \
	fi
TO_BUILD := $(BUILD_UNPACK_DIR) $(TO_BUILD)




#
# Patches
#
# See note below about search path.
#

DEBIAN_PATCHES_DIR := $(DEBIAN_DIR)/patches
DEBIAN_PATCHES_SERIES := $(DEBIAN_PATCHES_DIR)/series
PATCHES := $(shell [ -e '$(DEBIAN_PATCHES_SERIES)' ] && sed -e '/^\s*\#/d' '$(DEBIAN_PATCHES_SERIES)')
BUILD_PATCHES_DIR := $(BUILD_DEBIAN_DIR)/patches
BUILD_PATCHES_SERIES := $(BUILD_PATCHES_DIR)/series
BUILD_PATCHES := $(PATCHES:%=$(BUILD_PATCHES_DIR)/%)

ifneq "$(PATCHES)" ""

#export QUILT_PATCHES=$(DEBIAN_PATCHES_DIR)

FORCE:

$(BUILD_PATCHES_DIR): FORCE
	rm -rf '$@'
	mkdir -p '$@'

$(BUILD_PATCHES_SERIES): $(BUILD_PATCHES_DIR) $(DEBIAN_PATCHES_SERIES)
	@echo "Installing patches in $(BUILD_PATCHES_DIR):"
	cp '$(DEBIAN_PATCHES_SERIES)' '$@'


# This searches for patches first in Debian's patch directory and then
# in the unibuild-packaging directory (../..), allowing Debian to add
# its own patches or override others.
$(BUILD_PATCHES_DIR)/%: $(BUILD_PATCHES_SERIES)
	@[ -e "$(DEBIAN_PATCHES_DIR)/$(notdir $@)" ] && cp -v "$(DEBIAN_PATCHES_DIR)/$(notdir $@)" '$@' || true
	@[ -e "$(DEBIAN_PATCHES_DIR)/../../$(notdir $@)" ] && cp -v "$(DEBIAN_PATCHES_DIR)/../../$(notdir $@)" '$@' || true
	@[ ! -e "$@" ] || echo "  $(notdir $@)"
	@[ -e "$@" ] || (echo "Can't find patch $(notdir $@)" && false)


TO_BUILD += $(PATCHES:%=$(BUILD_PATCHES_DIR)/%)
endif


# Targets

# This is detritus from mk-build-deps
BUILD_DEPS_PACKAGE := $(SOURCE)-build-deps


# TODO: --build flag should be removed after we can get an original
# tarball for all build methods (tarball/source directory/none)

build: $(TO_BUILD) $(PRODUCTS_DIR)
	@printf "\nInstall Dependencies\n\n"
	cd $(BUILD_UNPACK_DIR) \
		&& mk-build-deps --root-cmd=sudo --install --remove \
			--tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
			'debian/control'
	@printf "\nBuild Package $(SOURCE) $(VERSION)\n\n"
	(((( \
		cd $(BUILD_UNPACK_DIR) && dpkg-buildpackage --build=any,all \
			--root-command=fakeroot --no-sign 2>&1 ; \
		echo $$? >&3 \
	) \
	| tee $(BUILD_LOG) >&4) 3>&1) \
	| (read XS; exit $$XS) \
	) 4>&1

	find '$(BUILD_DIR)' \
		'(' -name "*.deb" -o -name "*.changes" -o -name "*.buildinfo" ')' \
		-exec cp {} '$(PRODUCTS_DIR)' ';'


# This target is for internal use only.
_built:
	@if [ ! -d '$(PRODUCTS_DIR)' ] ; \
	then \
		printf "\nPackage is not built.\n\n" ; \
		false ; \
	fi

install: _built
	@printf "\nInstall packages:\n"
	@find '$(PRODUCTS_DIR)' -name '*.deb' \
		| fgrep -v '-build-deps' \
		| sed -e 's|^.*/||; s/^/  /'
	@echo
	@find '$(PRODUCTS_DIR)' -name '*.deb' \
		| fgrep -v '-build-deps' \
		| sed -e 's|^|./|g' \
		| $(SUDO) xargs apt-get -y --reinstall install


# Copy the products to a destination named by PRODUCTS_DEST
install-products: $(PRODUCTS_DIR)
ifndef PRODUCTS_DEST
	@printf "\nERROR: No PRODUCTS_DEST defined for $@.\n\n"
	@false
endif
	@if [ ! -d "$(PRODUCTS_DEST)" ] ; then \
	    printf "\nERROR: $(PRODUCTS_DEST) is not a directory.\n\n" ; \
	    false ; \
	fi
	find "$(PRODUCTS_DIR)" \( \
		-name '*.deb' -o -name '*.changes' -o -name '*.buildinfo' \
		\) -exec cp {} "$(PRODUCTS_DEST)" \;


# TODO: This doesn't work.
uninstall:
	@printf "\nUninstall packages:\n"
	@awk '$$1 == "Package:" { print $$2 }' ./unibuild/unibuild-packaging/deb/control \
	| ( while read PACKAGE ; do \
	    echo "    $${PACKAGE}" ; \
	    yes | $(SUDO) apt remove -f $$PACKAGE ; \
	    done )


dump: _built
	@find '$(PRODUCTS_DIR)' -name "*.deb" \
	| ( \
	    while read DEB ; \
	    do \
	        echo "$$DEB" | sed -e 's|^$(PRODUCTS_DIR)/||' | xargs -n 1 printf "\n%s:\n" ; \
	        dpkg --contents "$$DEB" ; \
	        echo ; \
	    done)

# Make this available so the primitive build process can tell if
# loading up was successful.
UNIBUILD_MAKE_FULLY_INCLUDED := 1
