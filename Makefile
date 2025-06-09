#
# Makefile for Unibuild
#

ifdef RELEASE
UNIBUILD_OPTS += --release
endif

UNIBUILD=./unibuild/unibuild/libexec/unibuild $(UNIBUILD_OPTS)

ifdef START
UNIBUILD_BUILD_OPTS += --start $(START)
endif

ifdef STOP
UNIBUILD_BUILD_OPTS += --stop $(STOP)
endif

BUILD_LOG=unibuild-log
TO_CLEAN += $(BUILD_LOG)

REPO=unibuild-repo
TO_CLEAN += $(REPO)

default: $(REPO)

# Figure out what needs to be run to get root.
ifeq ($(shell id -u),0)
  RUN_AS_ROOT :=
else
  RUN_AS_ROOT := sudo
endif


# Figure out what this system has for installing packages.
ifneq ($(wildcard /etc/redhat-release),)
  ifneq ($(shell command -v dnf),)
    PACKAGE_INSTALLER := dnf
  else ifneq ($(shell command -v yum),)
    PACKAGE_INSTALLER := yum
  endif
else ifneq ($(wildcard /etc/debian_version),)
  PACKAGE_INSTALLER := apt-get
else
  $(error "No support on this distribution.")
endif


build:
ifeq ($(PACKAGE_INSTALLER),apt-get)
	$(RUN_AS_ROOT) $(PACKAGE_INSTALLER) update
endif
ifneq ($(PACKAGE_INSTALLER),apt-get)
	$(RUN_AS_ROOT) $(PACKAGE_INSTALLER) install -y createrepo
endif
	$(RUN_AS_ROOT) $(PACKAGE_INSTALLER) install -y m4
	(((( \
		$(UNIBUILD) build $(UNIBUILD_BUILD_OPTS) ; \
		echo $$? >&3 \
	) \
	| tee $(BUILD_LOG) >&4) 3>&1) \
	| (read XS; exit $$XS) \
	) 4>&1
	$(UNIBUILD)


release:
	RELEASE=1 $(MAKE)


$(REPO): build
	(((( \
		mkdir -p $@ ; \
		$(UNIBUILD) gather $$(readlink -e '$@') ;\
		echo $$? >&3 \
	) \
	| tee -a $(BUILD_LOG) >&4) 3>&1) \
	| (read XS; exit $$XS) \
	) 4>&1




clean:
	find . -name unibuild-work | xargs rm -rf
	find . -name unibuild-log | xargs rm -rf
	rm -rf $(TO_CLEAN)


todo:
	grep -F -r TODO .
