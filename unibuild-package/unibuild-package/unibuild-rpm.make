#
# Generic Makefile for RPMs
#


#
# NO USER-SERVICEABLE PARTS BELOW THIS LINE
#

ifndef UNIBUILD_PACKAGE_MAKE
$(error "Include unibuild-package.make, not an environment-specific template.")
endif


# RPM Directory

# We don't care about rpm directories in anything we built
RPM_DIR := $(shell find . -type d -name "rpm" | egrep -ve '^./$(UNIBUILD_DIR)/')
ifeq "$(RPM_DIR)" ""
$(error "Unable to find rpm directory.")
endif
ifneq "$(words $(RPM_DIR))" "1"
$(error "Found more than one rpm directory.  There can be only one.")
endif


# Spec file and things derived from it

SPEC := $(shell find '$(RPM_DIR)' -name '*.spec')
SPEC_BASE := $(notdir $(SPEC))

ifeq "$(words $(SPEC))" "0"
  $(error No spec in the $(RPM_DIR) directory)
endif
ifneq "$(words $(SPEC))" "1"
  $(error $(RPM_DIR) contains more than one spec file)
endif

VERSION := $(shell rpm -q --queryformat="%{version}\n" --specfile '$(SPEC)')
SOURCE_FILES := $(shell spectool -S $(SPEC) | awk '{ print $$2 }')
PATCH_FILES := $(shell spectool -P $(SPEC) | awk '{ print $$2 }')

#
# RPM Build Directory
#

BUILD_RPMS=$(BUILD_DIR)/RPMS
BUILD_SOURCES=$(BUILD_DIR)/SOURCES
BUILD_SPECS=$(BUILD_DIR)/SPECS
BUILD_SRPMS=$(BUILD_DIR)/SRPMS

BUILD_SUBS=\
	$(BUILD_RPMS) \
	$(BUILD_SOURCES) \
	$(BUILD_SPECS) \
	$(BUILD_SRPMS)


TO_BUILD += $(BUILD_SUBS)

# Source files installed in the build directory
INSTALLED_SOURCE_FILES := $(SOURCE_FILES:%=$(BUILD_SOURCES)/%)

$(BUILD_SUBS):
	mkdir -p '$@'


#
# Patches
#

# Patch files will either be in the same directory with the RPM spec
# or the packaging directory above it.

# Enable this to force an error.
#PATCH_FILES += INTENTIONALLY-BAD.patch

LOCATED_PATCH_FILES := \
	$(wildcard $(PATCH_FILES:%=$(RPM_DIR)/%)) \
	$(wildcard $(PATCH_FILES:%=$(RPM_DIR)/../%))

LOCATED_PATCH_FILE_NAMES := $(notdir $(LOCATED_PATCH_FILES))

INSTALLED_PATCH_FILES := $(PATCH_FILES:%=$(BUILD_SOURCES)/%)

MISSING_PATCH_FILES := $(filter-out $(LOCATED_PATCH_FILE_NAMES),$(PATCH_FILES))

$(INSTALLED_PATCH_FILES): $(BUILD_SOURCES)
ifneq "$(MISSING_PATCH_FILES)" ""
	@echo
	@printf "ERROR: Unable to locate one or more of the following patch files:\n"
	@printf " $(MISSING_PATCH_FILES:%=    %\n)"
	@echo
	@printf "Each should exist in one of these directories:\n"
	@printf "    $(RPM_DIR)\n    $(dir $(RPM_DIR))\n"
	@echo
	@false
endif
ifneq "$(words $(LOCATED_PATCH_FILES))" "0"
	cp $(LOCATED_PATCH_FILES) $(BUILD_SOURCES)
endif


$(BUILD_DIR):: $(SPEC) $(BUILD_SPECS) $(INSTALLED_SOURCE_FILES) $(INSTALLED_PATCH_FILES)
	cp $(SPEC) $(BUILD_SPECS)


#
# Source files
#

ifeq "$(words $(SOURCE_FILES))" "1"
  TARBALL_EXISTS := $(shell [ -e '$(SOURCE_FILES)' ] && echo 1 || true)
else
  # Go with whatever's in the source file.
  TARBALL_EXISTS=1
endif


ifeq "$(TARBALL_EXISTS)" "1"

# Have tarball(s), just need to copy into $(BUILD_SOURCES)

TO_BUILD += $(SOURCE_FILES:%=$(BUILD_SOURCES)/%)

$(BUILD_SOURCES)/%: % $(BUILD_SOURCES)
	cp '$(notdir $@)' '$@'

else

# Have a tarball, need to generate it in $(BUILD_SOURCES)

TARBALL_SOURCE := $(shell echo $(SOURCE_FILES) | sed -e 's/-[^-]*\.tar\.gz$$//')
TARBALL_NAME := $(TARBALL_SOURCE)-$(VERSION)
TARBALL_FULL := $(TARBALL_NAME).tar.gz

TARBALL_BUILD := $(BUILD_SOURCES)/$(TARBALL_NAME)
BUILD_SOURCE_TARBALL := $(BUILD_SOURCES)/$(TARBALL_FULL)

$(BUILD_SOURCE_TARBALL): $(BUILD_SOURCES)
	cp -r '$(TARBALL_SOURCE)' '$(TARBALL_BUILD)'
	cd '$(BUILD_SOURCES)' && tar czf '$(TARBALL_FULL)' '$(TARBALL_NAME)'
	rm -rf '$(TARBALL_BUILD)'

TO_BUILD += $(BUILD_SOURCE_TARBALL)

endif


# Spec file in the build directory

BUILD_SPEC_FILE := $(BUILD_SPECS)/$(SPEC_BASE)
$(BUILD_SPEC_FILE): $(SPEC)
	cp '$<' '$@'
TO_BUILD += $(BUILD_SPEC_FILE)



#
# Useful Targets
#

ifdef NO_DEPS
  RPM=rpm
  RPMBUILD=rpmbuild
else
  RPM=rpm-with-deps
  RPMBUILD=rpmbuild-with-deps
endif

build:: $(TO_BUILD) $(PRODUCTS_DIR)
	(((( \
		$(RPMBUILD) -ba \
			--define '_topdir $(shell cd $(BUILD_DIR) && pwd)' \
			$(BUILD_SPEC_FILE) 2>&1 ; \
		echo $$? >&3 \
	) \
	| tee $(BUILD_LOG) >&4) 3>&1) \
	| (read XS; exit $$XS) \
	) 4>&1
	find $(BUILD_DIR)/RPMS -name '*.rpm' | xargs -I{} cp {} '$(PRODUCTS_DIR)'
	find $(BUILD_DIR)/SRPMS -name '*.rpm' | xargs -I{} cp {} '$(PRODUCTS_DIR)'


dump::
	@if [ -d "$(BUILD_RPMS)" ] ; then \
	    for RPM in `find $(BUILD_RPMS) -name '*.rpm'` ; do \
	    	echo `basename $${RPM}`: ; \
	     	rpm -qpl $$RPM 2>&1 | sed -e 's/^/\t/' ; \
	     	echo ; \
	    done ; \
        else \
	    echo "RPMs are not built." ; \
	    false ; \
	fi



# Install the built packages.  This is done in two phases so it can be
# done with YUM (or DNF): Reinstall anything that's already installed,
# then install anything that isn't.  This is the YUMmy equivalent of
# rpm -Uvh.

# Figure out which YUM-like installer to use, preferring DNF.
PATH_WORDS := $(subst :, ,$(PATH))
PATH_SEARCH := \
	$(addsuffix /dnf,$(PATH_WORDS)) \
	$(addsuffix /yum,$(PATH_WORDS))
YUM := $(firstword $(wildcard $(PATH_SEARCH)))
ifndef YUM
$(error "Unable to find YUM or DNF on this system.")
endif


INSTALL_INSTALLED=$(TMP_DIR)/install-installed
INSTALL_NOT_INSTALLED=$(TMP_DIR)/install-not-installed
install:: $(TMP_DIR)
	rm -f "$(INSTALL_INSTALLED)" "$(INSTALL_NOT_INSTALLED)"
	@for PACKAGE in `find $(BUILD_RPMS) -name '*.rpm'`; do \
	    SHORT=`basename "$${PACKAGE}" | sed -e 's/.rpm$$//'` ; \
	    rpm --quiet -q "$${SHORT}" && LIST_OUT="$(INSTALL_INSTALLED)" || LIST_OUT="$(INSTALL_NOT_INSTALLED)" ; \
	    echo "$${PACKAGE}" >> "$${LIST_OUT}" ; \
	done
	@if [ -s "$(INSTALL_INSTALLED)" ]  ; then \
		xargs sudo $(YUM) -y reinstall < "$(INSTALL_INSTALLED)" ; \
	fi
	@if [ -s "$(INSTALL_NOT_INSTALLED)" ] ; then \
		xargs sudo $(YUM) -y install < "$(INSTALL_NOT_INSTALLED)" ; \
	fi



uninstall::
	rpm -q --specfile "$(SPEC)" | xargs sudo yum -y erase


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
	find "$(PRODUCTS_DIR)" -name '*.rpm' -exec cp {} "$(PRODUCTS_DEST)" \;


# Placeholder for running unit tests.
test::
	@true
