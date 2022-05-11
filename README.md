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
   * RPM
   * RPMBuild
 * On Debian-based Systems:
   * Apt
   * DPkg


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

## The `unibuild-order` File

The order in which the packages are built is determined by the
contents of `unibuild-order`.  This is a flat file containing a list
of package names to be built.  Each package is found in a same-named
directory (e.g., the package `foo` would be located in the directory
`./foo`).

To allow intelligent decision making about what packages to build on
what platforms, `unibuild-order` is processed with the [GNU M4 Macro
Processor](https://www.gnu.org/software/m4).  To assist in this
process, Unibuild makes the following macros available:

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


## Package Subdirectories

Each package to be built as part of a repository 


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
| `gather` | Gathers the products of building each package into a repository |
| `macros` | Displays the macros available for use in `unibuild-order` files and their values on this system |
| `order` | Processes the `unibuild-order` file and displays the results |

The `--help` switch may be used with all commands for further
information on invoking them.

Generally, the `build` and `clean` commands are all that should be
required in normal use.



## Preparing Individual Packages

As noted above, each package to be built as part of a repository lives
in its own directory.  Naming the directory to match the name of the
package is a good convention, it is not required and exceptions should
be made where prudent.  For example, a package called `python-foo`
might end up producing an installable product called `python36-foo` on
some RPM-based systems.


### The `Makefile`

Every package directory contains a `Makefile` that includes the
Unibuild packaging template:

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


### The `unibuild-packaging` Directory



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
|   |   |-- series
|   |   +-- debian-only-bugfix.patch
|   |-- rules
|   |--source
|      +-- format
|
|-- rpm                       RPM Packaging
|    |-- foomatic.spec
|    +-- rpm-only-bugfix.patch
|
|-- common-bugfix-1.patch     Common patches
+-- common-bugfix-2.patch
```

### Raw Sources



```
foomatic/
    Makefile
    foomatic/
        ...foomatic sources...
        unibuild-packaging/
            deb
            rpm
```
Makefile:
```
AUTO_TARBALL := 1
include unibuild/unibuild.make
```



### Tarball

```
foomatic/
    Makefile
    foomatic-1.23.tar.gz
    unibuild-packaging/
        deb
        rpm
```

The Makefile

```
include unibuild/unibuild.make
```





## Building Repositories with Unibuild

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

## Hello World

Packaged with this distribution is a subdirectory called `hello-world`
that builds three packages: `hello` on all systems, `hello-rpm` on
RPM-based systems and `hello-deb` on Debian-based systems.  Each
package installs a command in `/usr/bin` named after itself.
