# Multibuild

Multibuild extends the Unibuild by building multiple products, each
with their own finished package repository and then merging those
repositories into one.


To run Multibuild:
```
$ multibuild [ DIR ]
```

Where `DIR` is the directory where the `multbuild-order` file
(described below) lives.  If not provided, the current directory (`.`)
will be used.

For each 


## Configuration File (`multibuild-order`)

The configuration for Multibuild is a plain text file with single-line
directives: in this format:

```
NAME [ NAME-OPTIONS ] BUILD-TYPE [ BUILD-TYPE-ARGUMENTS ]
```

`NAME` is a unique name for the build.  Any characters valid in a
filename except whitespace are valid.

The `NAME-OPTIONS` are:

 * `--once` - Build once only.
 * `--no-collect` - Don't collect the results into the final repo.

`BUILD-TYPE` determines where Multibuild should get the source code to
build the sub-repository.  `BUILD-TYPE-ARGUMENTS` vary by build type
and are documented below.

Comments are supported; a pound sign (`#`) will be removed along with
any other characters between it and the end of the line.

Examples:
```
hello-world   --once --no-collect copy   /some/shared/dir/hello-world
hello-again   --once --no-collect direct /home/me/work/hello-again
owamp                             git    --branch 5.0.0 https://github.com/perfsonar/owamp.git
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

In this example, if `product3` is going to be developed and is
dependent on `product1` and `product2`, `product3` can be cloned and
built after its dependencies have been acquired and built:
```
product1 --once --no-collect git    https://github.com/example/product1.git
product2 --once --no-collect git    https://github.com/example/product2.git
product3                     direct .
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

`REPOSITORY` is a Git repository

`OPTIONS` are any of the following:

 * `--checkout B` - After cloning, check out branch `B`.

Example:
```
git --branch release https://github.com/some-org/kafoobulator.git
```


### `null` - Build an empty repository

Usage: `null`

Example:
```
null
```
