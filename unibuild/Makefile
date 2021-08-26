#
# Build a package with Unibuild
#

AUTO_TARBALL := 1

include unibuild/unibuild.make

foo:
	@printf "\nUninstall packages:\n"
	@awk '$$1 == "Package:" { print $$2 }' ./unibuild/packaging/deb/control \
	| ( while read PACKAGE ; do \
	    echo "    $${PACKAGE}" ; \
	    yes | sudo apt remove -f $$PACKAGE ; \
	    done )





