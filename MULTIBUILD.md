# Multibuild

Multibuild extends Unibuild by building multiple products, each
with their own finished package repository and then merging those
repositories into one.


## Running Multibuild

To run Multibuild:
```
$ multibuild [ PATH ]
```

Where `PATH ` is one of the following:

 * The path to a directory where a configuration file (described
   below) named `multibuild-order` can be found.  The build will take
   place in that directory.

 * The path to a configuration file.  The build will take place in the
   same directory as that file.

If no `PATH` is provided, the current directory (`.`) will be used.


## Configuration File (`multibuild-order`)

The configuration for Multibuild is a plain text file with single-line
directives: in this format:

```
NAME [ NAME-OPTIONS ] BUILD-TYPE [ BUILD-TYPE-ARGUMENTS ]
```

`NAME` is a unique name for the build.  Any characters valid in a
filename except whitespace are valid.

The `NAME-OPTIONS` are:

 * `--no-collect` - Don't collect the results of this build into the
  final package repository.  Use this to build and install
  prerequisites.

 * `--once` - Build once only.  This is useful for doing development.

The `BUILD-TYPE` determines the method Multibuild should get the
source code to build the sub-repository.  The `BUILD-TYPE-ARGUMENTS`
are build-type-specific.  Both are documented below.

Comments are supported; a pound sign (`#`) will be removed along with
any other characters between it and the end of the line.

Examples:
```
hello-world   --once --no-collect copy   /some/shared/dir/hello-world
hello-again   --once --no-collect direct /home/me/work/hello-again
owamp                             git    --branch 5.0.0 https://github.com/perfsonar/owamp.git
```


## Build Types


### `copy` - Copy a path and build it

This build type will create a copy of the directory at `PATH` in its
work area and do the build there.

Usage: `copy PATH`

Example:
```
copy /share/source-for-project
```


### `direct` - Build directly at a path

This build type does its build in the directory at `PATH`.  Use of
this build type is recommended only as a development tool for building
prerequisites for a repository.

Usage: `direct PATH`

Example:
```
direct .
```


### `git` - Clone a Git repository

Usage: `git [ OPTIONS ] REPOSITORY

`REPOSITORY` is a Git repository that can be retrieved using `git
clone`.

`OPTIONS` are any of the following:


 * `--checkout B` - After cloning, check out branch `B`.
 * `--subdir D` - Build starting in subdirectory `D`.

Example:
```
# Build the 'release' branch of Kafoobulator
git --checkout release https://github.com/some-org/kafoobulator.git

# Build Unibuild's Hello World example
git --subdir hello-world main https://github.com/perfsonar/unibuild.git
```


### `null` - Build an empty repository

Usage: `null`

Example:
```
null
```


## Use Cases

### Build for Release

Multiple products can be built sequentially into a single package
repository for release by acquiring them using Git and building them.

Example:
```
product1 git --checkout release https://github.com/example/product1.git
product2 git --checkout release https://github.com/example/product2.git
product3 git --checkout release https://github.com/example/product3.git
```

### Development

Prior to doing development on a product, its prerequisites can be
built and installed.

Example:
```
# These are product3's dependencies.  Build them once and don't make a
# repository of the products.
product1 --once --no-collect git https://github.com/example/product1.git
product2 --once --no-collect git https://github.com/example/product2.git

# This is the code to be developed.  It will be built every time
# Multibuild is run but its products will not be collected into a
# repo.
product3 --no-collect direct .
```
