#
# Unibuild-package Makefile
#

# TODO: When you run the default target (i.e., just 'make'), it builds
# twice.  Not really a problem, just an annoyance.

default: build


# Figure out what needs to be run to get root.

ifeq ($(shell id -u),0)
  RUN_AS_ROOT :=
else
  RUN_AS_ROOT := sudo
endif


# Figure out what kind of packages are used by this system.  This is
# verbatim from unibuild-package's unibuild.make.

ifneq ($(wildcard /etc/redhat-release),)
  PACKAGE_FORMAT := rpm
  ifeq ($(shell command -v dnf),)
    INSTALL_PACKAGE := yum
  else
    INSTALL_PACKAGE := dnf
  endif
else ifneq ($(wildcard /etc/debian_version),)
  PACKAGE_FORMAT := deb
else
  $(error Unable to determine the package format on this system.)
endif



ifndef STAGE2

# Stage 1: Do prep and launch the real thing.

# This makes sure things we need to build are installed.
%:
ifeq ($(PACKAGE_FORMAT),rpm)
	$(RUN_AS_ROOT) $(INSTALL_PACKAGE) -y install make rpmdevtools
else
	apt-get -y install make devscripts equivs
endif
	$(MAKE) STAGE2=1 $@

else

# Stage 2: Build the package.

AUTO_TARBALL=1
BUILD_PATH=./unibuild-package

INC=$(BUILD_PATH)
# Eat a healthy dose of our own dog food
include $(BUILD_PATH)/unibuild.make

endif
