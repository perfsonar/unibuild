# Unibuild

Unibuild is a kit for building repositories of software packaged in
RPM or Debian format.  It consists of two parts:

 * A packager that can operate on OS-specific packaging information
  (RPM specifications or Debian packaging data)

 * A set of programs that oversee the construction of multiple
   packages and their assembly into a completed repository suitable
   for the system where they are invoked



# Installation

## Prerequisites

 * A POSIX-compliant shell
 * POSIX-compliant command-line utilities
 * GNU Make
 * GNU M4
 * Sudo
 * On RPM-based Systems:
   * The Bourne Again Shell (BASH)
   * RPM (From `rpm`)
   * RPMBuild (From `rpm-build`)
   * Spectool (From `rpmdevtools`, with no hyphen)
   * Which (From `which`)
   * Quick install:  `yum -y install git make m4 rpm-build rpmdevtools createrepo which`
 * On Debian-based Systems:
   * Apt
   * DPkg and dpkg-dev
   * Dev Scripts
   * Equivs
   * Quick install: `apt install -y dpkg dpkg-dev devscripts equivs`


Builds done by a user other than `root` (recommended) require that the
user can acquire superuser privileges using `sudo`.  For unattended
builds, this access must require no human interaction.


# Build and Install

In the directory containing this file, run `make` as `root` or a user
able to do passwordless `sudo`.  Unibuild will install any
dependencies, self-build and install.  A repository containing all
packages will be placed in the `unibuild-repo` directory.

Short summary:

```
$ git clone https://github.com/perfsonar/unibuild.git
$ cd unibuild
$ make
```

This process builds and installs the following packages:

 * `unibuild` - The unibuild program and supporting files
 * `unibuild-package` - A set of `Makefile` templates used to build
   individual packages.
 * `rpm-with-deps` - A utility used by the RPM packager built only on
   RPM-based systems.


Note that the process of building and installing Unibuild is done
almost entirely with Unibuild itself.  Failures to build successfully
unrelated to the prerequisites likely indicates a problem with
Unibuild.  Please report those as bugs.




# Using Unibuild

Building a repository with Unibuild requires establishing a directory
where all of the sources live and a file the determines what packages
get built and in what order.  For example:

```
my-project/
|
+--  unibuild-order       File that determines build order
     |
     |-- foo/             Directories containing packages
     |-- bar/
     |-- baz-o-matic/
     |-- quux/
     +-- xyzzy/
```

Each package to be built as part of a repository lives in its own
directory.  Naming the directory to match the package is a good
convention but is not required.  Exceptions should be made where
prudent.  For example, a package called `python-foo` might end up
producing an installable product called `python3-foo` on some systems.


## The `unibuild-order` File

The order in which the packages are built is determined by the
contents of `unibuild-order`.  This is a flat file containing a list
of package names to be built separated by newlines.  Comments in the
file begin with a pound sign (`#`) and empty lines are ignored.

Each package is found in a same-named directory (e.g., the package
`foo` would be located in the directory `./foo`).

To allow intelligent decision making about what packages to build on
what platforms, `unibuild-order` is processed with the [GNU M4 Macro
Processor](https://www.gnu.org/software/m4).


### Unibuild-Provided Macros

Unibuild makes the following macros available to M4 based on
information gathered from the system running it:

| Macro | Description | Example |
|-------|-------------|---------|
| `OS` | Operating system as reported by `uname(1)` | `Linux` |
| `DISTRO` | Operating system distribution, empty of not applicable | `CentOS` |
| `FAMILY` | Operating system family, empty where not applicable | `RedHat` |
| `RELEASE` | Operating system release | `7.9.2009` |
| `CODENAME` | Codename of operating system release | `Core` |
| `MAJOR` | Major version of `RELEASE`, empty if not present | `7` |
| `MINOR` | Minor version of `RELEASE`, empty if not present | `9` |
| `PATCH` | Patch version of `RELEASE`, empty if not present | `2009` |
| `PACKAGING` | Type of packaging used by this system (Currently `deb` or `rpm`) | `rpm` |
| `ARCH` | Machine architecture as reported by `uname(1)` | `x86_64` |

The list of provided macros and their values can be displayed by
running `unibuild macros`.

While all of M4's processing features are available, most decisions
can be made using the [if-else or multibranch
construct](https://www.gnu.org/software/m4/manual/html_node/Ifelse.html#Ifelse)
and the [integer expression
evaluator](https://www.gnu.org/software/m4/manual/html_node/Eval.html#Eval).
For example:

```
# Built everywhere, unconditionally.
foo

# Built only on RPM systems:
ifelse(PACKAGING,rpm,bar)

# Built everywhere other than Debian-derived systems on Intel:
ifelse(FAMILY/ARCH,deb/x86_64,,baz-o-matic)

# Built only on versions of Ubuntu prior to 20:
ifelse(DISTRO/eval(MAJOR < 20),Ubuntu/1,quux)

# Built everywhere except on Debian 9 or anything Debian on ARM 64 or
# PowerPC 64.
ifelse(DISTRO/MAJOR,Debian/9,,
       FAMILY/ARCH,Debian/arm64,,
       FAMILY/ARCH,Debian/ppc64el,,
       xyzzy)
```


### User-Defined Macros

Additional macros can be defined by invoking `unibuild` with the `--define` switch, e.g.:

```
$ unibuild --define THIS=foo --define THAT=bar macros
ARCH                 x86_64
CODENAME             Core
DISTRO               CentOS
FAMILY               RedHat
MAJOR                7
MINOR                9
OS                   Linux
PACKAGING            rpm
PATCH                2009
RELEASE              7.9.2009
THAT                 bar
THIS                 foo
```

Note that `--define` can be used to override the definitions of macros
provided by Unibuild (e.g., `OS` or `ARCH`).


### Bundles

Some projects separate packages into bundles that are built as
separate packages containing only dependencies on those packages.
Unibuild allows a package to be marked for a bundle by adding a
`--bundle` switch` to the line naming the package, e.g.:

```
foo --bundle bar
```

The list of packages marked for a bundle may be retrived using the
command `unibuild order --bundle BUNDLE-NAME`.

Packages where no `--bundle` option is specified are automatically
included in a bundle named `none`.


### Skipping Installation

In some cases, it is preferable to skip the installation step for a
package once its build is complete.  To do this, add a `--no-install`
switch to the line naming the package, e.g.:

```
foo --no-install
```


## Unibuild Commands

Unibuild is invoked by running `unibuild` on the command line with a
command and optional arguments.  IIf no command is provided, the
default command will be `build`.

These are the available commands:


| Command | Description |
|---------|-------------|
| `build` | Builds all packages (equivalent to `unibuild make clean build install`) and gathers the results into a repository (equivalent to `unibuild gather`) |
| `clean` | Removes all build by-products (equivalent to `unibuild make clean`) |
| `make` | Runs `make` against targets in each package directory |
| `gather` | Gathers the products of building each package into a repository and places it in the `unibuild-repo` directory |
| `macros` | Displays the macros available for use in `unibuild-order` files and their values on this system |
| `order` | Processes the `unibuild-order` file and displays the results |
| `version` | Displays the version of unibuild | 

The `--help` switch may be used with all commands for further
information on invoking them.

Generally, the `build` and `clean` commands are all that should be
required in normal use.

### Timestamps

Unibuild adds a timestemp to all packages it produces that reflects
the time Unibuild was invoked.  This is a common practice to allow
versions of a package produced during repeated development builds to
be considered later by package managers.

To disable this behavior for released versions of packages, add the
`--release` flag to the `unibuild` invocation (e.g., `unibuild --release`).



# Preparing Individual Packages

Each package in a repository is built using a `Makefile` template
provided by the `unibuild-package` package.


## The `Makefile`

Every package directory contains a `Makefile` that used `include` to
incorporate the Unibuild packaging template:

```
# This is optional depending on circumstances.  See below.
# AUTO_TARBALL := 1

include unibuild/unibuild.make
```

Packages may be built from a tarball for cases where the software is
acquired elsewhere or a directory of sources for cases where it is
locally-maintained.  Defining `AUTO_TARBALL` instructs Unibuild's Make
template to produce a tarball from the sources before proceeding to
build the package.

### Targets

The template includes four targets:

| Target | Shorthand | Description |
|--------|-----------|-------------|
| `build` | `b` | Builds the package(s).  This is the default target. |
| `install` | `i` | Installs the built package(s). |
| `dump` | `d` | Produces a list of the built packages and their contents. |
| `clean` | `c` | Removes all by-products of the `build` target. |

In addition to the shorthands, the template provides several
additional abbreviations for groups of targets: `cb`, `cbd`, `cbi`,
`cbic` and `cdbc`.



## The `unibuild-packaging` Directory

How packages are constructed is determined by the contents of the
`unibuild-packaging` directory.  This directory may be located in the
top-level package directory in cases where the product is being built
from a tarball:

```
foomatic/
|
|-- foomatic-1.23.tar.gz
|-- Makefile
+-- unibuild-packaging/
```

or when building directly from a source tree:

```
foomatic/
|
|-- foomatic/
|   |-- unibuild-packaging/
|   |-- Makefile
|   +-- foomatic.c
+-- Makefile
```

The directory itself contains subdirectories for each type of package
that need to be built and, optionally, patches that are applied to all
types of packaging.  (See _Patches_, below.)  The currently-supported
methods of packaging are `rpm` and `deb`.

```
unibuild-packaging/
|
|-- deb                       Debian Packaging
|   |-- changelog
|   |-- compat
|   |-- control
|   |-- copyright
|   |-- gbp.conf
|   |-- patches
|   |   |-- series            Includes common-bugfix-{1,2}
|   |   +-- debian-only-bugfix.patch
|   |-- rules
|   |--source
|      +-- format
|
|-- rpm                       RPM Packaging
|    |-- foomatic.spec        Includes common-bugfix-{1,2}
|    +-- rpm-only-bugfix.patch
|
|-- common-bugfix-1.patch     Common patches
+-- common-bugfix-2.patch
```

Unibuild will automatically gather up all of the patches required and
place them in the right location for the operating system's package
builder to find and use them.  Note that if the package builder
requires the patches be listed in packaging files, that must be done
manually.




# Hello World

Packaged with this distribution is a subdirectory called `hello-world`
containing a small, fully-functional example of multiple packages
built, installed and gathered into a repository.

There are three packages:

 * `hello` - Built on all systems
 * `hello-rpm` - Built only on RPM-based systems
 * `hello-deb` - Built only on Debian-based systems

Each package installs a program in `/usr/bin` named after itself.

Note that building Hello WOrld requires that Unibuild be installed on
the system.


# Docker Containers

Containers containing a minimal OS installation and Unibuild pre-installed are available for use with Docker.

| Family | Distribution | Version | Container |
|--------|--------------|:-------:|-----------|
| Red Hat | CentOS | 7 | `ghcr.io/perfsonar/unibuild/el7:latest` |
| Red Hat | Alma Linux | 8 | `ghcr.io/perfsonar/unibuild/el8:latest` |
| Red Hat | Alma Linux | 9 | `ghcr.io/perfsonar/unibuild/el9:latest` |
| Debian | Debian | 10 | `ghcr.io/perfsonar/unibuild/d10:latest` |
| Debian | Ubuntu | 18 | `ghcr.io/perfsonar/unibuild/u18:latest` |
| Debian | Ubuntu | 20 | `ghcr.io/perfsonar/unibuild/u20:latest` |

Debian family containers are provided for different CPU architectures.
