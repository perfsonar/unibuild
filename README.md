# Unibuild

Unibuild is a kit for building repositories of software packaged in
RPM or Debian format.  It consists of two parts:

 * Unibuild-Package, which automatically builds packaged software
   based on suppled OS-specfic packaging information (RPM
   specifications or Debian packaging data).

 * Unibuild, which oversees construction of multiple packages using
   Unibuild-Package and combines the finished products into a
   repository suitable for the system where it was invoked.



## Installation

### Prerequisites

 * A POSIX-compliant shell
 * POSIX-compliant command-line utilities
 * GNU Make
 * Sudo
 * RPM-based Systems:
   * The Bourne Again Shell (BASH)
   * RPM
   * RPMBuild
 * Debian-based Systems:
   * Apt
   * DPkg


Builds done by a user other than `root` (recommended) require that the
user can acquire superuser privileges using `sudo`.  For unattended
builds, this access must require no human interaction.


### Building

In the directory containing this file, run `make`.  Unibuild will
install any dependencies, self-build and install.  A repository
containing all packages will be paced in the `REPO` directory.



## Using Unibuild

```
TOP
 |
 +-- unibuild-order
 |
 +-- package1
 +-- package2
 +-- ...
 +-- packageN
```



TODO: See ...Unibuild... for details
TODO: See ...Unibuild-Package... for details
TODO: Hello world example
