#
# Build a package with Unibuild
#

AUTO_TARBALL := 1


# Try to include the installed template or one nearby in the sources.
# This is a bit of a hack but will really only take effect when
# building "clean" when unibuild-package hasn't been built and
# installed yet.  Think of it as eating more of our own dog food.

-include unibuild/unibuild.make

ifndef UNIBUILD_MAKE_FULLY_INCLUDED
  $(warning *** No installed unibuild-package; trying copy in sources.)
  BUILD_PATH=../unibuild-package/unibuild-package
  -include $(BUILD_PATH)/unibuild.make
endif

ifndef UNIBUILD_MAKE_FULLY_INCLUDED
  $(error No installed unibuild-package found anywhere.)
endif
