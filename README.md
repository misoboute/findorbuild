# FindOrBuild (FOB)
A CMake module set that functions as a package manager that downloads and 
builds packages that can't be found using `find_package`.

It can be used within a CMake list file to search for packages. It can handle 
multiple versions of the same package and multiple configuration builds of the 
same version.

To use FOB in your build system, simply download the `FOBBootstrap.cmake` module 
and include it in your list file. The bootstrapper will download the latest
version of the other modules (if already not downloaded) and includes the
main client module (`FindOrBuild.cmake`).

From then on, you can use the `fob_find_or_build` macro instead of the plain 
old `find_package` to search for packages.

_Note_: Macros, functions, and variables whose names begin with a single
underscore are intended for internal usage and are considered part of the 
implementation of the module set. Only use the macros and
functions that begin with `fob_` or variables that begin with `FOB_` (without a
leading underscore).

## Macros and Functions

### fob_find_or_build
Use the `fob_find_or_build` macro to find a package instead of the native 
cmake `find_package`.
Its syntax is similar to that of `find_package`. In fact all the arguments 
passed to this macro, except those that are used by the macro itself, are
forwarded to the `find_package` when looking for packages.

It tries to find the package (using native `find_package`) within existing 
packages (both within those provided by the system and within those
previously built by `FindOrBuild`) and, if the package cannot be found,
it tries to retrieve and build the the package of interest, and then calls 
the `find_package` again to find the built package.

The order of searching within the system-provided and FOB-built packages
is determined by the value of the `USE_SYSTEM_PACKAGES` parameter whose default
value comes from the `FOB_USE_SYSTEM_PACKAGES_OPTION` cache variable.
<A NAME="FOB_USE_SYSTEM_PACKAGES_OPTIONS">
The possible options are:
  `ALWAYS`: Only search within the system-provided packages and, if not found,
      do _NOT_ retrieve and build the package.
  `FIRST`: First search within the system-provided, then within the FOB-built
      packages and, if not found, retrieve and build the package.
  `LAST`: First search within the the FOB-built, then within system-provided
      packages and, if not found, retrieve and build the package.
  `NEVER`: Only search within the FOB-built packages and, if not found,
      retrieve and build the package.

If you want to use the package built with a specific set of cache arguments,
pass those argument settings using the parameter `CFG_ARGS`
using the syntax `CFG_ARGS -DARGUMENT1=VALUE1 -DARGUMENT2=VALUE2 ...`
Including the `CFG_ARGS` argument implies and overrides the value of `NEVER` for 
`USE_SYSTEM_PACKAGES` because configuration arguments can only be tracked for 
packages built by FOB.

Sample:
```cmake
fob_find_or_build(GTest 1.10 REQUIRED
    CFG_ARGS
        -DBUILD_SHARED_LIBS=true
        -Dgtest_force_shared_crt=true
)
```

The above call will look for the GTest package version 1.10 (or 1.10.0) 
within the packages previously built by FindOrBuild using the 
cache arguments `-DBUILD_SHARED_LIBS=true;-Dgtest_force_shared_crt=true`.
If the package with the given specification is not found, it will try to 
download, build, install, and find the package. The `REQUIRED` argument will be 
passed to the final `find_package` after the package is built.

## Variables and Options

### FOB_USE_SYSTEM_PACKAGES_OPTION
Determines the default value for the `USE_SYSTEM_PACKAGES` parameter passed 
to fob_find_or_build.
See the [possible values](#FOB_USE_SYSTEM_PACKAGES_OPTIONS).

### FOB_ENABLE_PACKAGE_RETRIEVE
Determines whether we should retrieve, build, and install packages that 
are not found in system packages or those previously built and installed by FOB.

# Extending FOB
When FindOrBuild fails to find a certain package called `MyPackage` and decides 
that it has to build it, it tries to download a builder module named 
`FOB-Retrieve-MyPackage.cmake` from the `findorbuild` repository. It then
includes the retrieve module in a CMake list file, generates, and builds it.

The retrieve module, in short, is responsible for defining a CMake 
ExternalProject that downloads, builds, and installs the package of interest.
It is important that is external project is added using 
`fob_add_ext_cmake_project` rather than the `ExternalProject` module directly 
since the `fob_add_ext_cmake_project` performs some other steps that are 
necessary for managing and maintaining different versions of each package.

When the retrieve module is loaded, it will have access to all the arguments
passed as part of the `CFG_ARGS` argument to `fob_find_or_build` as 
variable. 

It will also have access to some other variables and functions.

## Variables

### FOB_REQUESTED_VERSION
The version of the package requested through the call to `fob_find_or_build`.

## Functions

### fob_normalize_version_number
It converts the version number to a normalized semantic version number with
exactly four components. If the version number already has four components,
it will not be changed. If it has less than four components, enough `0` 
components will be added to the version number so it will have exactly four
components.

Sample:
```cmake
set(VERSION 1.10)
fob_normalize_version_number(VERSION)
```
After the call to `fob_normalize_version_number` above, the variable `VERSION`
will be equal to `1.10.0.0`.

### fob_add_ext_cmake_project
This is a wrapper around calls to a series of calls `ExternalProject` 
functions and additional services. These calls add an external project using 
`ExternalProject_Add` and then add separate build and install steps for each
of the configs in `CMAKE_CONFIGURATION_TYPES`.

The arguments passed to `fob_normalize_version_number` are either consumed by 
the function itself or are passed to the underlying `ExternalProject_Add`. 
Those consumed by the function are:

- `PDB_INSTALL_DIR`: On MSVC builds this specifies the directory where the
compile debug information files should be installed to.
- `BUILD_DISTINGUISHING_VARS`: A list of cache argument variables, the change 
in the value of each one of them, warrants a different build. These arguments
could be those that tell the build system to use static vs shared CRT or 
any other parameter whose change will produce a distinct build that should 
be maintained separately in the FOB package storage.

Other additional services that this function provides is creating the 
directory structure for the external project. It also makes sure that a 
distinct build root is created for each package/version and that for each
distinct set of CFG_ARG values and platform/architecture/ABI..., a distinct 
set of build/install/tmp directories are allocated.

It also transmits the values of some of the cmake variables from the current 
generation to the external project to make sure that the project builds with 
the right toolset and the right configuration. Among these variables are:
`CMAKE_C_COMPILER`, `CMAKE_CXX_COMPILER`, `CMAKE_PREFIX_PATH`.

For examples of how to use these functions and variables and how to define 
your own retrieve modules, check out the existing retrieve modules in 
the FOB repository.

# Contribute/Contact
If you want to add retrieve modules or make improvements, pull requests are 
welcome! Also feel free to [write to me](mailto:misoboute@gmail.com) so I'll 
grant you the needed permissions.
