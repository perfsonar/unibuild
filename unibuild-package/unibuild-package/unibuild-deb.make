#
# Generic Makefile for Debian packagess
#

#
# NO USER-SERVICEABLE PARTS BELOW THIS LINE
#

ifndef UNIBUILD_PACKAGE_MAKE
$(error Include unibuild-package.make, not an environment-specific template.)
endif

# Don't expect user interaction
RUN_AS_ROOT += DEBIAN_FRONTEND=noninteractive

# Basic package information

# We don't care about rpm directories in anything we built
DEBIAN_DIR := $(shell find . -type d -name "deb" | egrep -ve '^./$(UNIBUILD_DIR)/')
ifeq "$(DEBIAN_DIR)" ""
$(error Unable to find Debian (deb) directory.)
endif
ifneq "$(words $(DEBIAN_DIR))" "1"
$(error Found more than one Debian (deb) directory.  There can be only one.)
endif
DEBIAN_DIR_PARENT := $(DEBIAN_DIR)/../..


CONTROL := $(DEBIAN_DIR)/control

SOURCE := $(shell awk '-F: ' '$$1 == "Source" { print $$2 }' $(CONTROL))
ifeq "$(SOURCE)" ""
$(error Unable to find source name in $(CONTROL).)
endif

SRCFORMAT := $(shell grep -Eo '([a-z]+)' '$(DEBIAN_DIR)/source/format')

CHANGELOG := $(DEBIAN_DIR)/changelog
# Break down VERSION and REVISION
VERSION := $(shell dpkg-parsechangelog -l '$(CHANGELOG)' \
    | sed -n 's|Version: \([^-]*\)\(-.*\)*$$|\1|p' \
    )
# And leaving out any +dfsg.x suffix when looking for TARBALL
NODFSG_VERSION := $(shell dpkg-parsechangelog -l '$(CHANGELOG)' \
        | sed -n 's|Version: \([^-+]*\)\(+dfsg[.0-9]*\)\?\(-.*\)*$$|\1|p' \
    )
REVISION := $(shell dpkg-parsechangelog -l '$(CHANGELOG)' \
    | sed -n 's|Version: \([^-]*\)\(-.*\)*$$|\2|p' \
    )

ifeq "$(VERSION)" ""
$(error Unable to find version in $(CHANGELOG).)
endif

# If we have a UNIBUILD_TIMESTAMP, we are building a snapshot release
ifdef UNIBUILD_TIMESTAMP
VERSION := $(VERSION)~$(UNIBUILD_TIMESTAMP)
ifeq "$(SRCFORMAT)" "native"
  NEW_DEB_VERSION := $(VERSION)
else
  NEW_DEB_VERSION := $(VERSION)$(REVISION)
endif
endif


# Build Directory and its Contents

# This is speculative; not all packages have a source tarball.  If
# there is one, accept one with or without a version number.

TARBALL_SUFFIX := .tar.gz

SOURCE_TARBALLS := $(wildcard $(SOURCE)-$(NODFSG_VERSION)$(TARBALL_SUFFIX) $(SOURCE)$(TARBALL_SUFFIX))
ifeq ($(words $(SOURCE_TARBALLS)),0)
SOURCE_TARBALL :=
else ifeq  ($(words $(SOURCE_TARBALLS)),1)
  SOURCE_TARBALL := $(SOURCE_TARBALLS)
  ifeq ($(SOURCE_TARBALL),$(SOURCE)$(TARBALL_SUFFIX))
    SOURCE_DIR := $(SOURCE)
  else
    SOURCE_DIR := $(SOURCE)-$(VERSION)
  endif
else
$(error "Found more than one potential source tarball.")
endif

BUILD_UNPACK_DIR := $(BUILD_DIR)/$(SOURCE)

BUILD_DEBIAN_DIR := $(BUILD_UNPACK_DIR)/debian
TAR_UNPACK_DIR := $(SOURCE_DIR)-unpack


ORIG_TARBALL := $(SOURCE)_$(VERSION).orig$(TARBALL_SUFFIX)
SOURCE_VERSION := $(SOURCE)-$(VERSION)
BUILD_ORIG_DIR := $(BUILD_DIR)/orig
BUILD_ORIG_PACKAGE_DIR := $(BUILD_ORIG_DIR)/$(SOURCE_VERSION)

$(BUILD_ORIG_DIR): $(PRODUCTS_DIR)
	rm -rf '$@'
	mkdir -p '$@'

$(BUILD_UNPACK_DIR): $(PRODUCTS_DIR) $(BUILD_ORIG_DIR)
	rm -rf '$@'
	mkdir -p '$@/$(SOURCE_DIR)'
ifneq ($(SOURCE_TARBALL),)
	@printf "\nUnpacking tarball $(SOURCE_TARBALL).\n\n"
	(cd '$@/$(SOURCE_DIR)' && tar xzf - --strip-components=1) < '$(SOURCE_TARBALL)'
	mv '$@/$(SOURCE_DIR)' '$@/$(TAR_UNPACK_DIR)'
	ls -a '$@/$(TAR_UNPACK_DIR)' \
		| egrep -vxe '[.]{1,2}' \
		| xargs -I % mv '$@/$(TAR_UNPACK_DIR)'/% '$@'
	rmdir '$@/$(TAR_UNPACK_DIR)'
else ifeq ($(words $(wildcard $@/$(SOURCE))),1)
	@printf "\nBuilding from source directory $(SOURCE).\n\n"
	(cd '$(SOURCE)' && tar cf - .) | (cd '$@' && tar xpf -)
else ifneq ($(DEBIAN_DIR_PARENT),$(dir $(BUILD_DIR)))
	@printf "\nBuilding from source directory $(DEBIAN_DIR_PARENT).\n\n"
	(cd '$(DEBIAN_DIR_PARENT)' && tar cf - .) | (cd '$@' && tar xpf -)
else
	@printf "\nNo tarball or source directory.\n\n"
endif
	@printf "\nBuilding 'orig' tarball $(ORIG_TARBALL).\n\n"
	mkdir -p $(BUILD_ORIG_PACKAGE_DIR)
ifneq ($(SOURCE_TARBALL),)
	-# Copy the original tarball without modification
	cp $(SOURCE_TARBALL) $(PRODUCTS_DIR)/$(ORIG_TARBALL)
else
	-# Build from the unpacked sources since one did not exist
	(cd '$@' && tar cf - .) | (cd $(BUILD_ORIG_PACKAGE_DIR) && tar xpf -)
	-# Debian packaging guidelines dictate that the "orig" tarball
	-# must not change if the software does not, so remove any
	-# packaging information before creating it.
	find '$(BUILD_ORIG_PACKAGE_DIR)' -name 'unibuild-packaging' -type d | xargs rm -rf
	(cd $(BUILD_ORIG_DIR) && tar cf - $(SOURCE_VERSION) | gzip -n ) > $(PRODUCTS_DIR)/$(ORIG_TARBALL)
endif
	cp $(PRODUCTS_DIR)/$(ORIG_TARBALL) $(BUILD_UNPACK_DIR)/..
	@printf "\nInstalling Debian build into $(BUILD_DEBIAN_DIR)..\n\n"
	rm -rf '$(BUILD_DEBIAN_DIR)'
	cp -r '$(DEBIAN_DIR)' '$(BUILD_DEBIAN_DIR)'
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
	@printf "\nInstalling patches in $(BUILD_PATCHES_DIR):"
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


ifeq ($(shell id -u),0)
  ROOT_CMD :=
else
  ROOT_CMD := --root-cmd=sudo
endif





build:: $(TO_BUILD) $(PRODUCTS_DIR)
ifdef UNIBUILD_TIMESTAMP
	@printf "\nUpdate changelog for SNAPSHOT build\n\n"
	( cd $(BUILD_UNPACK_DIR) \
        && dch -c debian/changelog -Mb --distribution=UNRELEASED --newversion=$(NEW_DEB_VERSION) \
        -- 'SNAPSHOT build for '$(VERSION)' via Unibuild' \
	)
endif
	@printf "\nInstall Dependencies\n\n"
	cd $(BUILD_UNPACK_DIR) \
		&& mk-build-deps $(ROOT_CMD) --install --remove \
			--tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
			'debian/control' \
		&& rm -f *-build-deps_*.buildinfo *-build-deps_*.changes
	@printf "\nBuild Package $(SOURCE) $(VERSION)\n\n"
	(((( \
		cd $(BUILD_UNPACK_DIR) && dpkg-buildpackage -sa \
			--root-command=fakeroot --no-sign 2>&1 ; \
		echo $$? >&3 \
	) \
	| tee $(BUILD_LOG) >&4) 3>&1) \
	| (read XS; exit $$XS) \
	) 4>&1

	find '$(BUILD_DIR)' \( \
		-name "*.deb" -o -name "*.dsc" -o -name "*.changes" -o -name "*.buildinfo" -o -name "*.build" -o -name "*.tar.*" -o -name "*.diff.gz" \
		\) -exec cp {} '$(PRODUCTS_DIR)' ';'


# This target is for internal use only.
_built:
	@if [ ! -d '$(PRODUCTS_DIR)' ] ; \
	then \
		printf "\nPackage is not built.\n\n" ; \
		false ; \
	fi

install:: _built
	@printf "\nInstall packages:\n"
	@find '$(PRODUCTS_DIR)' -name '*.deb' \
		| fgrep -v -- '-build-deps' \
		| sed -e 's|^.*/||; s/^/  /'
	@echo
	@find '$(PRODUCTS_DIR)' -name '*.deb' \
		| fgrep -v -- '-build-deps' \
		| sed -e 's|^|./|g' \
		| $(RUN_AS_ROOT) xargs apt-get -y --reinstall install


# Copy the products to a destination named by PRODUCTS_DEST and add
# additional info to the repo.

REPO_UNIBUILD := $(PRODUCTS_DEST)/unibuild
DEBIAN_PACKAGE_ORDER := $(REPO_UNIBUILD)/debian-package-order

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
		-name "*.deb" -o -name "*.dsc" -o -name "*.changes" -o -name "*.buildinfo" -o -name "*.build" -o -name "*.tar.*" -o -name "*.diff.gz" \
		\) -exec cp {} "$(PRODUCTS_DEST)" \;
	mkdir -p "$(REPO_UNIBUILD)"
	sed -e ':a;/\\\s*$$/{N;s/\\\s*\n//;ba}' "$(CONTROL)" \
		| awk '$$1 == "Source:" { print $$2; exit }' \
		>> "$(DEBIAN_PACKAGE_ORDER)"


# TODO: This doesn't work.
uninstall::
	@printf "\nUninstall packages:\n"
	@awk '$$1 == "Package:" { print $$2 }' ./unibuild/unibuild-packaging/deb/control \
	| ( while read PACKAGE ; do \
	    echo "    $${PACKAGE}" ; \
	    yes | $(RUN_AS_ROOT) apt remove -f $$PACKAGE ; \
	    done )


dump:: _built
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
