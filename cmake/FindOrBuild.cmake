# This module is the main module of FindOrBuild that defines the 
# find_or_build macro. The find_or_build macro is the central element of 
# this module and is used instead of the native find_package with a similar 
# syntax.
# Refer to find_or_build documentation for more information.

# Note: Macros, functions, and variables whose names begin with a single
# underscore are intended for internal module usage. Only use the macros and
# functions that begin with fob_ or variables that begin with FOB_ (without a
# leading underscore).

if(FOB_FIND_OR_BUILD_INCLUDED)
    return()
endif(FOB_FIND_OR_BUILD_INCLUDED)
set(FOB_FIND_OR_BUILD_INCLUDED 1)

# Sets a value to a variable (as default) if it is not already set.
function(fob_set_default_var_value VAR_NAME DEFAULT_VAL)
    if(NOT DEFINED ${VAR_NAME})
        set(${VAR_NAME} ${DEFAULT_VAL} PARENT_SCOPE)
    endif()
endfunction(fob_set_default_var_value)

# Save the current defined state and value of a variable so it can be restored
# later using fob_pop_var
function(fob_push_var VAR_NAME)
    if (DEFINED ${VAR_NAME})
        set(_push_${VAR_NAME} ${${VAR_NAME}} PARENT_SCOPE)
    else()
        unset(${VAR_NAME} PARENT_SCOPE)
    endif()
endfunction(fob_push_var)

# Restore the defined state and value of a variable previously saved using
# fob_push_var
function(fob_pop_var VAR_NAME)
    if (DEFINED _push_${VAR_NAME})
        set(${VAR_NAME} ${_push_${VAR_NAME}} PARENT_SCOPE)
    else()
        unset(${VAR_NAME} PARENT_SCOPE)
    endif()
endfunction(fob_pop_var)

# Compares two variables representing boolean values and sets the specified
# output variable to ON if they both represent the same boolean value and
# to OFF otherwise.
function(fob_are_bools_equal OUTVAR BOOL1 BOOL2)
    set(RESULT OFF)
    if((BOOL1 AND BOOL2) OR ((NOT BOOL1) AND (NOT BOOL2)))
        set(RESULT ON)
    endif()
    set(${OUTVAR} ${RESULT} PARENT_SCOPE)
endfunction()

# Turns a ;-separated list into a string by joining the elements of the list
# using the $<SEMICOLON> generator expression as glue. This should be used
# when passing a ;-separated to a shell command that expects ;-separated lists.
# This will prevent the list to be expanded into multiple arguments on the 
# command line.
macro(fob_semicolon_escape_list OUT_VAR)
    string(JOIN $<SEMICOLON> ${OUT_VAR} ${ARGN})
endmacro(fob_semicolon_escape_list)

# Get the path to the home directory of the user running cmake.
function(fob_get_home_dir HOME_VAR)
    if (UNIX)
        file(TO_CMAKE_PATH "$ENV{HOME}" HOME)    
    elseif(WIN32)
        file(TO_CMAKE_PATH "$ENV{HOMEDRIVE}$ENV{HOMEPATH}" HOME)
    endif()
    set(${HOME_VAR} ${HOME} PARENT_SCOPE)
endfunction(fob_get_home_dir)

set(FOB_USE_SYSTEM_PACKAGES_OPTION LAST CACHE STRING 
    "Determines the default value for the USE_SYSTEM_PACKAGES parameter \
passed to fob_find_or_build."
)

set_property(CACHE FOB_USE_SYSTEM_PACKAGES_OPTION
    PROPERTY STRINGS ALWAYS FIRST LAST NEVER)

if(DEFINED $ENV{FOB_STORAGE_ROOT})
    cmake_path(CONVERT $ENV{FOB_STORAGE_ROOT} 
        TO_CMAKE_PATH_LIST _FOB_DEFAULT_PACKAGE_ROOT NORMALIZE)
else()
    fob_get_home_dir(HOME)
    set(_FOB_DEFAULT_PACKAGE_ROOT "${HOME}/.FindOrBuild")
endif()

set(FOB_STORAGE_ROOT ${_FOB_DEFAULT_PACKAGE_ROOT} CACHE STRING 
    "The path where built packages are installed to and where we will search \
for packages."
)

option(FOB_ENABLE_PACKAGE_RETRIEVE
    "Determines whether we should retrieve, build, and install packages that \
are not found in system packages or those previously built and installed by us"
    true)

# Prepend the specified path to the PATH environment variable in the current
# configure process. All the commands launched by execute_process will
# inherit the new PATH value.
function(fob_prepend_to_env_path PATH)
    cmake_path(NATIVE_PATH PATH NORMALIZE PATH_NATIVE)
    set(ENV{PATH} "${PATH_NATIVE};$ENV{PATH}")
endfunction()

# Call this macro within a specific compatibility checker module to declare
# all variables that the module checks. Simply pass the names of variables 
# to this macro. It will set or reset the compatibility flag.
# If a non-declared variable is encountered in the requested arguments, 
# it causes further processing of the compatibility module and 
macro(fob_declare_compatibility_variables)
    set(FOB_COMPATIBILITY_VARIABLES_DECLARED ON)
    set(_DELARED_VARIABLES "${ARGN}")
    foreach(REQUEST_VAR ${FOB_REQUEST_CONFIG_VARIABLES})
        if(NOT (REQUEST_VAR IN_LIST _DELARED_VARIABLES))
            message(WARNING "The requested config variable ${REQUEST_VAR} is \
not declared by the compatibility module ${CMAKE_CURRENT_LIST_FILE}. Either \
the compatibility file is from an older version or you are requesting a \
nonexistent variable.")
            set(FOB_IS_COMPATIBLE OFF)
            # return from the compatibility module (not the macro)
            return() 
        endif()
    endforeach(REQUEST_VAR)
endmacro(fob_declare_compatibility_variables)

# Get a list of compiler IDs that are binary compatible with the given 
# compiler ID. This compatibility mapping is speculative and based on little 
# research and almost no experiment. Its validity can be tested.
function(fob_get_binary_compatible_compilers 
    COMPILER_ID COMPATIBLE_COMPILER_SET_VAR)
    set(APPLE_COMPILERS AppleClang GNU)
    set(CLANG_COMPILERS Clang GNU Intel IntelLLVM OpenWatcom PathScale PGI)
    set(FUJITSU_COMPILERS Fujitsu FujitsuClang)
    set(BORLAND_COMPILERS Embarcadero Borland)
    set(IBM_COMPILERS XL XLClang VisualAge zOS)

    if(APPLE AND COMPILER_ID IN_LIST APPLE_COMPILERS)
        set(${COMPATIBLE_COMPILER_SET_VAR} ${APPLE_COMPILERS} PARENT_SCOPE)
        return()
    endif()
    foreach(COMPILER_SET 
        CLANG_COMPILERS FUJITSU_COMPILERS
        BORLAND_COMPILERS IBM_COMPILERS
    )
        if(COMPILER_ID IN_LIST COMPILER_SET)
            set(${COMPATIBLE_COMPILER_SET_VAR} ${COMPILER_SET} PARENT_SCOPE)
            return()
        endif()
    endforeach(COMPILER_SET)

    set(${COMPATIBLE_COMPILER_SET_VAR} ${COMPILER_ID} PARENT_SCOPE)
endfunction(fob_get_binary_compatible_compilers) 

# Checks whether a build configuration root directory (CFG_DIR formed as 
# ${FOB_STORAGE_ROOT}/${PACKAGE_NAME}/${PACKAGE_VERSION}/${CONFIG_HASH_ID})
# contains an installation of the package that is compatible with the
# current build configuration and the requested configuration arguments 
# (CFG_ARGS). The result is placed in the variable named by OUTVAR.
function(_does_cfg_dir_match_args OUTVAR MODULE_NAME CFG_DIR CFG_ARGS)
    unset(FOB_IS_COMPATIBLE)
    include(${CFG_DIR}/compatibility/Generic.cmake)
    if(NOT FOB_IS_COMPATIBLE OR NOT CFG_ARGS)
        set(${OUTVAR} ${FOB_IS_COMPATIBLE} PARENT_SCOPE)
        return()
    endif()
    set(FOB_REQUEST_CONFIG_VARIABLES)
    foreach(REQUIRED_CFG ${CFG_ARGS})
        set(ARG_REGEX "^-D\\s*([a-zA-Z_][0-9a-zA-Z_]*)=(.*)")
        if(REQUIRED_CFG MATCHES ${ARG_REGEX})
            set(REQUIRED_ARG_NAME ${CMAKE_MATCH_1})
            set(REQUIRED_ARG_VALUE ${CMAKE_MATCH_2})
            set(${REQUIRED_ARG_NAME} ${REQUIRED_ARG_VALUE})
            list(APPEND FOB_REQUEST_CONFIG_VARIABLES ${REQUIRED_ARG_NAME})
        endif()
    endforeach(REQUIRED_CFG)
    set(FOB_COMPATIBILITY_VARIABLES_DECLARED OFF)
    include(${CFG_DIR}/compatibility/${MODULE_NAME}.cmake OPTIONAL)
    if(NOT FOB_COMPATIBILITY_VARIABLES_DECLARED)
        set(FOB_IS_COMPATIBLE ${FOB_COMPATIBILITY_VARIABLES_DECLARED})
    endif()
    set(${OUTVAR} ${FOB_IS_COMPATIBLE} PARENT_SCOPE)
endfunction(_does_cfg_dir_match_args)

# Get a list of install prefix paths within ${FOB_STORAGE_ROOT} for the 
# package specified by PACKAGE_NAME and configuration arguments (CFG_ARG).
# It returns all the existing versions of the package if their config args
# match. The version matching is done later on by find_package as usual.
# The result is placed in the variable named by PATHS_VAR.
function(_get_all_paths_for_package_in_fob_storage PACKAGE_NAME PATHS_VAR)
    set(OPTIONS)
    set(SINGLE_VAL)
    set(MULTI_VAL CFG_ARGS)
    cmake_parse_arguments(
        ARG "${OPTIONS}" "${SINGLE_VAL}" "${MULTI_VAL}" ${ARGN})

    set(PKG_ROOT ${FOB_STORAGE_ROOT}/${PACKAGE_NAME})
    file(GLOB VERSION_DIRS LIST_DIRECTORIES true ${PKG_ROOT}/*)
    list(TRANSFORM VERSION_DIRS APPEND /*)
    file(GLOB CONFIG_DIRS LIST_DIRECTORIES true ${VERSION_DIRS})
    list(FILTER CONFIG_DIRS EXCLUDE REGEX "(download|src)")
    set(MATCHING_CFG_DIRS)
    foreach(CFG_DIR ${CONFIG_DIRS})
        unset(IS_MATCH)
        _does_cfg_dir_match_args(
            IS_MATCH ${PACKAGE_NAME} ${CFG_DIR} "${ARG_CFG_ARGS}")
        if(IS_MATCH)
            list(APPEND MATCHING_CFG_DIRS ${CFG_DIR})
        endif()
    endforeach(CFG_DIR)
    list(TRANSFORM MATCHING_CFG_DIRS APPEND /install)
    file(GLOB INSTALL_DIRS LIST_DIRECTORIES true ${MATCHING_CFG_DIRS})
    set(${PATHS_VAR} ${INSTALL_DIRS} PARENT_SCOPE)
endfunction(_get_all_paths_for_package_in_fob_storage)

# Find the package specified by the given name (PACKAGE_NAME), other 
# find_package arguments (including version, components, etc), and an optional
# set of configuration arguments (CFG_ARG) ONLY within the FOB storage of 
# packages (FOB_STORAGE_ROOT).
macro(_fob_find_package_ours_only PACKAGE_NAME FIND_ARGS)
    set(_FOB_OPTIONS)
    set(_FOB_SINGLE_VAL)
    set(_FOB_MULTI_VAL CFG_ARGS)
    cmake_parse_arguments(_FFPOO
        "${_FOB_OPTIONS}" "${_FOB_SINGLE_VAL}" "${_FOB_MULTI_VAL}" ${FIND_ARGS})

    if(_FFPOO_CFG_ARGS)
        set(_FOB_CFG_ARGS_SETTING CFG_ARGS ${_FFPOO_CFG_ARGS})
    else()
        unset(_FOB_CFG_ARGS_SETTING)
    endif()

    fob_push_var(CMAKE_FIND_FRAMEWORK)
    fob_push_var(CMAKE_FIND_APPBUNDLE)
    set(CMAKE_FIND_FRAMEWORK LAST)
    set(CMAKE_FIND_APPBUNDLE LAST)
    
    _get_all_paths_for_package_in_fob_storage(
        ${PACKAGE_NAME} PKG_PATHS ${_FOB_CFG_ARGS_SETTING})

    list(APPEND CMAKE_PREFIX_PATH ${PKG_PATHS})
    list(REMOVE_DUPLICATES CMAKE_PREFIX_PATH)
    find_package(${PACKAGE_NAME}
        ${_FFPOO_UNPARSED_ARGUMENTS} PATHS ${PKG_PATHS})
    
    fob_pop_var(CMAKE_FIND_FRAMEWORK)
    fob_pop_var(CMAKE_FIND_APPBUNDLE)
endmacro(_fob_find_package_ours_only)

# Performs the first attempt at finding the package specified by the given 
# name (PACKAGE_NAME), other find_package arguments (including version, 
# components, etc), and an optional set of configuration arguments (CFG_ARGS).
# It will look in the FOB storage if the CFG_ARGS is provided or 
# USE_SYS_PACKAGES is set to either LAST or NEVER. It will look in the 
# system packages otherwise. The CFG_ARGS, if provided, must be part of 
# FIND_ARGS. 
macro(_fob_find_package_first_attempt USE_SYS_PACKAGES PACKAGE_NAME FIND_ARGS)
    if (${USE_SYS_PACKAGES} STREQUAL LAST OR ${USE_SYS_PACKAGES} STREQUAL NEVER)
        _fob_find_package_ours_only(${PACKAGE_NAME} "${FIND_ARGS}")
    else()
        find_package(${PACKAGE_NAME} ${FIND_ARGS})
    endif()
endmacro(_fob_find_package_first_attempt)

# Performs the second attempt at finding the package specified by the given 
# name (PACKAGE_NAME), other find_package arguments (including version, 
# components, etc), and an optional set of configuration arguments (CFG_ARGS).
# It will look in the FOB storage if the CFG_ARGS is provided or 
# USE_SYS_PACKAGES is set to either FIRST or NEVER. It will look in the 
# system packages otherwise. The CFG_ARGS, if provided, must be part of 
# FIND_ARGS. 
macro(_fob_find_package_second_attempt USE_SYS_PACKAGES PACKAGE_NAME FIND_ARGS)
    if (${USE_SYS_PACKAGES} STREQUAL FIRST OR 
        ${USE_SYS_PACKAGES} STREQUAL NEVER)
        _fob_find_package_ours_only(${PACKAGE_NAME} "${FIND_ARGS}")
    else()
        find_package(${PACKAGE_NAME} ${FIND_ARGS})
    endif()
endmacro(_fob_find_package_second_attempt)

# Checks whether a package specified by PACKAGE_NAME has been found by a
# prior call to find_package. 
# The result is placed in the variable named by OUTPUT_VAR.
function(_fob_is_package_found PACKAGE_NAME OUTPUT_VAR)
    # Some CMake find modules set the <UPPERCASE_PACKAGE_NAME>_FOUND variable
    # even if the package name passed to find_package is not in all uppercase.
    string(TOUPPER ${PACKAGE_NAME} _UPPERCASE_PACKAGE_NAME)
    if (${PACKAGE_NAME}_FOUND OR ${_UPPERCASE_PACKAGE_NAME}_FOUND)
        set(${OUTPUT_VAR} true PARENT_SCOPE)
    else()
        set(${OUTPUT_VAR} false PARENT_SCOPE)
    endif()
endfunction(_fob_is_package_found)

macro(_fob_find_in_existing_packages USE_SYS_PACKAGES PACKAGE_NAME FIND_ARGS)
    # First we need to see if the package can be found, so if a REQUIRED clause
    # is present, we remove it for the time being so the call doesn't fail.
    set(_FOB_MODIFIED_ARGS ${FIND_ARGS})
    if (NOT USE_SYS_PACKAGES STREQUAL ALWAYS AND FOB_ENABLE_PACKAGE_RETRIEVE)
        list(REMOVE_ITEM _FOB_MODIFIED_ARGS REQUIRED)
    endif()
    
    _fob_find_package_first_attempt(
        ${USE_SYS_PACKAGES} ${PACKAGE_NAME} "${_FOB_MODIFIED_ARGS}")
    
    _fob_is_package_found(${PACKAGE_NAME} _FOB_PKG_FOUND)

    if(NOT FOB_ENABLE_PACKAGE_RETRIEVE)
        set(_FOB_MODIFIED_ARGS ${FIND_ARGS})
    endif()

    if(NOT _FOB_PKG_FOUND AND 
        (${USE_SYS_PACKAGES} STREQUAL FIRST 
            OR ${USE_SYS_PACKAGES} STREQUAL LAST))
        _fob_find_package_second_attempt(
            ${USE_SYS_PACKAGES} ${PACKAGE_NAME} "${_FOB_MODIFIED_ARGS}")
    endif()    
endmacro(_fob_find_in_existing_packages)

# Use this function to convert a list of command line style cache initializers
# to a cache preloader script that can be passed to cmake command.
# Each command line style initializer looks like:
# -D<var>:<type>=<value>
#	or
# -D<var>=<value>
# The generated preloader file will be composed of one or more lines looking
# like this:
#
# set(<var> <value> CACHE <type> "..." FORCE)
# set(<var> <value> CACHE <type> "..." FORCE)
# set(<var> <value> CACHE)
# set(<var> <value> CACHE)
# set...
#
# The generated cache preloader file can be passed to the cmake command using:
# cmake -C <initial-cache> ...
function(fob_convert_cmdln_cache_args_to_cache_preloader
    CACHE_PRELOADER_FILE CACHE_ARGS)
    file(WRITE ${CACHE_PRELOADER_FILE} "")

    # The regex to match a single initializer of the form -D<var>:<type>=<value>
    # or -D<var>=<value> with capture groups for var, type, and value
    set(_cache_arg_typed_def_regex "^-D\\s*([a-zA-Z_][0-9a-zA-Z_]*)\
(:(BOOL|FILEPATH|PATH|STRING|INTERNAL))=(.*)")
    set(_cache_arg_typeless_def_regex "^-D\\s*([a-zA-Z_][0-9a-zA-Z_]*)=(.*)")

    # Care must be taken as each of the elements in CACHE_ARGS is not
    # necessarily a cache initializer definition. This is because some cache
    # initializers contain semicolons in their values and the semicolons
    # are interpreted as list separator in CMake. So each item in CACHE_ARGS
    # might be the beginning of an initializer or continuation of the list value
    # of the last one.
    foreach(_cache_arg ${CACHE_ARGS})
        string(REGEX MATCH ${_cache_arg_typed_def_regex}
            _matched_arg_typed "${_cache_arg}")
        string(REGEX MATCH ${_cache_arg_typeless_def_regex}
            _matched_arg_typeless "${_cache_arg}")
        if (_matched_arg_typed OR _matched_arg_typeless)
            # Beginning of an initializer
            if (_setter_line_ending)
                # This is not our first initializer. So we have to close the
                # definition for the last one.
                file(APPEND ${CACHE_PRELOADER_FILE} ${_setter_line_ending})
            endif (_setter_line_ending)

            # For typeless initializers, we'll take the type to be STRING.
            # Otherwise we won't be able to define a cache entry.
            if (_matched_arg_typed)
                string(REGEX REPLACE ${_cache_arg_typed_def_regex}
                    "\\1" _cache_arg_name "${_cache_arg}")
                string(REGEX REPLACE ${_cache_arg_typed_def_regex}
                    "\\3" _cache_arg_type "${_cache_arg}")
                string(REGEX REPLACE ${_cache_arg_typed_def_regex}
                    "\\4" _cache_arg_value "${_cache_arg}")
            else (_matched_arg_typed)
                string(REGEX REPLACE ${_cache_arg_typeless_def_regex}
                    "\\1" _cache_arg_name "${_cache_arg}")
                string(REGEX REPLACE ${_cache_arg_typeless_def_regex}
                    "\\2" _cache_arg_value "${_cache_arg}")
                set(_cache_arg_type STRING)
            endif (_matched_arg_typed)
            set(_setter_line_ending " CACHE ${_cache_arg_type} \
\"Generated by fob_convert_cmdln_cache_args_to_cache_preloader\" FORCE)\n")

            # Open new entry definition
            file(APPEND ${CACHE_PRELOADER_FILE}
                "\nset(${_cache_arg_name} \"${_cache_arg_value}\"")
        else (_matched_arg_typed OR _matched_arg_typeless)
            # So this is a continuation of the value of the last initializer.
            # We will just insert the semicolon back in an proceed.
            file(APPEND ${CACHE_PRELOADER_FILE} " ${_cache_arg}")
        endif (_matched_arg_typed OR _matched_arg_typeless)
    endforeach(_cache_arg)

    # Close the last entry definition
    if (_setter_line_ending)
        file(APPEND ${CACHE_PRELOADER_FILE} ${_setter_line_ending})
    endif (_setter_line_ending)

endfunction(fob_convert_cmdln_cache_args_to_cache_preloader)

# Use the _fob_include_and_build_in_cmake_time function to build the
# specified targets within one or more CMake files during processing of
# the current list.
# Syntax:
# _fob_include_and_build_in_cmake_time(
#		[PROJ_NAME <proj-name>] [PROJ_PATH <proj-path>]
#		MODULES <module1> [<module2> [<module3> ...]]
#		[TARGETS [<target1> [<target2> [<target3> ...]]]]
#		[CACHE_ARGS [-D<var1>:<type1>=<value1> [-D<var1>:<type1>=<value1> ...]]]
#
# The _fob_include_and_build_in_cmake_time command creates a new CMakeLists file
# using the specified input and then proceeds with configuration and building
# of the specified targets immediately.
# PROJ_NAME specifies an optional name for the project. If specified,
# project(<proj-name>) will be added.
# Use PROJ_PATH to specify a directory for the project to be created in and
# built. If ommitted, a random directory within the current binary directory
# is used for the project.
# MODULES names the list of CMake modules (files) to include within the created
# list file using include command. For each of the modules specified, a line
# of the form include(<moduleN>) is added to the created list file. At least
# one module must be passed.
# Use TARGETS to specify which targets to build after the project has been
# created and configured. If ommitted, the default targets are built.
# Use CACHE_ARGS to initialize the CMake cache for the created project using
# command line style initializers. Since the modules are loaded using CMake
# include command, you should probably initialize CMAKE_MODULE_PATH so the
# module(s) can be located.
# Example:
#	_fob_include_and_build_in_cmake_time(
#		PROJ_NAME MyProject
#		MODULES InitModule MainModule
#		CACHE_ARGS
#			-DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}
#			-DCMAKE_MODULE_PATH:STRING=${CMAKE_MODULE_PATH}
#	)
function(_fob_include_and_build_in_cmake_time)
    set(OPTIONS)
    set(SINGLE_VAL PROJ_NAME PROJ_PATH)
    set(MULTI_VAL MODULES TARGETS CACHE_ARGS)
    cmake_parse_arguments(
        ARG "${OPTIONS}" "${SINGLE_VAL}" "${MULTI_VAL}" ${ARGN})

    if(ARG_PROJ_NAME)
        set(PROJECT_LINE "project(${ARG_PROJ_NAME})")
    endif(ARG_PROJ_NAME)

    if(NOT ARG_MODULES)
        message(WARNING
"At least one module is needed by _fob_include_and_build_in_cmake_time")
        return()
    endif()
    
    set(LIST_FILE_CONTENTS
"cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})
${PROJECT_LINE}
list(APPEND CMAKE_MODULE_PATH \"${FOB_MODULE_DIR}\")
include(PackageUtils)
foreach(MOD \"${ARG_MODULES}\")
    include(\${MOD})
endforeach(MOD)
")

    if(NOT ARG_PROJ_PATH)
        string(RANDOM LENGTH 8 ARG_PROJ_PATH)
    endif(NOT ARG_PROJ_PATH)
    file(WRITE ${ARG_PROJ_PATH}/CMakeLists.txt ${LIST_FILE_CONTENTS})

    fob_convert_cmdln_cache_args_to_cache_preloader(
        ${ARG_PROJ_PATH}/InitCache.txt "${ARG_CACHE_ARGS}")

    set(_config_command ${CMAKE_COMMAND} 
        -C ${ARG_PROJ_PATH}/InitCache.txt -G "${CMAKE_GENERATOR}"
        -S ${ARG_PROJ_PATH} -B ${ARG_PROJ_PATH}/build
    )

    if(CMAKE_GENERATOR_PLATFORM)
        list(APPEND _config_command -A ${CMAKE_GENERATOR_PLATFORM})
    endif(CMAKE_GENERATOR_PLATFORM)
    if(CMAKE_GENERATOR_PLATFORM)
        list(APPEND _config_command -T ${CMAKE_GENERATOR_TOOLSET})
    endif(CMAKE_GENERATOR_PLATFORM)

    cmake_path(GET CMAKE_COMMAND PARENT_PATH PATH_TO_CMAKE_BIN_DIR)
    fob_prepend_to_env_path(${PATH_TO_CMAKE_BIN_DIR})

    execute_process(COMMAND ${_config_command})
    set(BUILD_DIR ${ARG_PROJ_PATH}/build)

    if(ARG_TARGETS)
        foreach(TGT ${ARG_TARGETS})
            execute_process(COMMAND ${CMAKE_COMMAND}
                --build ${BUILD_DIR} --target ${TGT})
        endforeach(TGT)
    else(ARG_TARGETS)
        execute_process(COMMAND ${CMAKE_COMMAND} --build ${BUILD_DIR})
    endif(ARG_TARGETS)
endfunction(_fob_include_and_build_in_cmake_time)

# Copies IN_STRING into the variable named by OUT_IS_VERSION if the string
# represents a valid semantic version number. If not it unsets the variable.
function(_fob_is_valid_version OUT_IS_VERSION IN_STRING)
    if(IN_STRING MATCHES [[[0-9]+(\.[0-9]+)?(\.[0-9]+)?(\.[0-9]+)?]])
        set(${OUT_IS_VERSION} ${IN_STRING} PARENT_SCOPE)
    else()
        unset(${OUT_IS_VERSION} PARENT_SCOPE)
    endif()
endfunction(_fob_is_valid_version)

# Find the retriever module for the requested package within the current
# CMAKE_MODULE_PATH and if not found, download the retriever module.
# It stores the path to the module in the specified variable.
function(_find_or_download_retriever_module MODULE_PATH_OUT_VAR PACKAGE_NAME)
    foreach(MOD_PATH ${CMAKE_MODULE_PATH})
        if(EXISTS ${MOD_PATH}/retrievers/${PACKAGE_NAME}.cmake)
            set(${MODULE_PATH_OUT_VAR} 
                ${MOD_PATH}/retrievers/${PACKAGE_NAME}.cmake PARENT_SCOPE)
            return()
        endif()
    endforeach(MOD_PATH)
    fob_download_fob_file_if_not_exists(
        cmake/retrievers/${PACKAGE_NAME}.cmake FILE_PATH)
    set(${MODULE_PATH_OUT_VAR} ${FILE_PATH} PARENT_SCOPE)
endfunction(_find_or_download_retriever_module)

# Start download, build, and installation of the package specified by 
# PACKAGE_NAME, version (the argument immediately after name), and an 
# optional set of build configuration arguments (CFG_ARGS).
function(_fob_download_build_install_package PACKAGE_NAME)
    set(OPTIONS)
    set(SINGLE_VAL)
    set(MULTI_VAL CFG_ARGS)
    cmake_parse_arguments(
        ARG "${OPTIONS}" "${SINGLE_VAL}" "${MULTI_VAL}" ${ARGN})

    set(EXT_PROJ_PATH ${CMAKE_BINARY_DIR}/fob/ExtProj/${PACKAGE_NAME})
    file(REMOVE_RECURSE ${EXT_PROJ_PATH})
    
    if(ARG_UNPARSED_ARGUMENTS)
        list(GET ARG_UNPARSED_ARGUMENTS 0 FIND_PKG_VER_ARG)
        _fob_is_valid_version(FIND_PKG_VER_ARG ${FIND_PKG_VER_ARG})
        if(FIND_PKG_VER_ARG VERSION_GREATER 0)
            set(REQUESTED_VER_CACHE_SETTING
                "-DFOB_REQUESTED_VERSION:STRING=${FIND_PKG_VER_ARG}")
        else()
            set(REQUESTED_VER_CACHE_SETTING)
        endif()
    endif()

    _find_or_download_retriever_module(RETRIEVER_MODULE_PATH ${PACKAGE_NAME})

    _fob_include_and_build_in_cmake_time(
        PROJ_NAME Retrieve${PACKAGE_NAME}
        MODULES ${RETRIEVER_MODULE_PATH}
        PROJ_PATH ${EXT_PROJ_PATH}
        CACHE_ARGS
            -DFOB_MODULE_DIR:PATH=${FOB_MODULE_DIR}
            -DFOB_STORAGE_ROOT:PATH=${FOB_STORAGE_ROOT}
            "-DCMAKE_MODULE_PATH:STRING=${CMAKE_MODULE_PATH}"
            "-DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}"
            "-DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}"
            "-DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}"
            -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET}
            "-DCMAKE_CONFIGURATION_TYPES:STRING=${CMAKE_CONFIGURATION_TYPES}"
            -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
            ${REQUESTED_VER_CACHE_SETTING}
            ${ARG_CFG_ARGS}
    )
endfunction(_fob_download_build_install_package)

# Use the `fob_find_or_build` macro to find a package instead of the native 
# cmake `find_package`.
# Its syntax is similar to that of `find_package`. In fact all the arguments 
# passed to this macro, except those that are used by the macro itself, are
# forwarded to the `find_package` when looking for packages.

# It tries to find the package (using native `find_package`) within existing 
# packages (both within those provided by the system and within those
# previously built by `FindOrBuild`) and, if the package cannot be found,
# it tries to retrieve and build the the package of interest, and then calls 
# the `find_package` again to find the built package.

# The order of searching within the system-provided and FOB-built packages
# is determined by the value of the `USE_SYSTEM_PACKAGES` parameter whose default
# value comes from the `FOB_USE_SYSTEM_PACKAGES_OPTION` cache variable.
# The possible options are:
#   `ALWAYS`: Only search within the system-provided packages and, if not found,
#       do _NOT_ retrieve and build the package.
#   `FIRST`: First search within the system-provided, then within the FOB-built
#       packages and, if not found, retrieve and build the package.
#   `LAST`: First search within the the FOB-built, then within system-provided
#       packages and, if not found, retrieve and build the package.
#   `NEVER`: Only search within the FOB-built packages and, if not found,
#       retrieve and build the package.

# If you want to use the package built with a specific set of cache arguments,
# pass those argument settings using the parameter `CFG_ARGS`
# using the syntax `CFG_ARGS -DARGUMENT1=VALUE1 -DARGUMENT2=VALUE2 ...`
# Including the `CFG_ARGS` argument implies and overrides the value of `NEVER` for 
# `USE_SYSTEM_PACKAGES` because configuration arguments can only be tracked for 
# packages built by FOB.

# Sample:
# ```cmake
# fob_find_or_build(GTest 1.10 REQUIRED
#     CFG_ARGS
#         -DBUILD_SHARED_LIBS=true
#         -Dgtest_force_shared_crt=true
# )
# ```

# The above call will look for the GTest package version 1.10 (or 1.10.0) 
# within the packages previously built by FindOrBuild using the 
# cache arguments `-DBUILD_SHARED_LIBS=true;-Dgtest_force_shared_crt=true`.
# If the package with the given specification is not found, it will try to 
# download, build, install, and find the package. The `REQUIRED` argument will be 
# passed to the final `find_package` after the package is built.
macro(fob_find_or_build PACKAGE_NAME)
    set(_FOB_OPTIONS)
    set(_FOB_SINGLE_VAL USE_SYSTEM_PACKAGES)
    set(_FOB_MULTI_VAL CFG_ARGS)
    cmake_parse_arguments(_FFOB
        "${_FOB_OPTIONS}" "${_FOB_SINGLE_VAL}" "${_FOB_MULTI_VAL}" ${ARGN})

    if(_FFOB_CFG_ARGS)
        set(_FFOB_USE_SYSTEM_PACKAGES NEVER)
        set(_FOB_CFG_ARGS_SETTING CFG_ARGS ${_FFOB_CFG_ARGS})
    else ()
        set(_FOB_CFG_ARGS_SETTING)
    endif()

    if(_FFOB_UNPARSED_ARGUMENTS)
        list(GET _FFOB_UNPARSED_ARGUMENTS 0 _FOB_FIND_PKG_VER_ARG)
        _fob_is_valid_version(
            _FOB_FIND_PKG_VER_ARG ${_FOB_FIND_PKG_VER_ARG})
    else()
        set(_FOB_FIND_PKG_VER_ARG)
    endif()

    fob_set_default_var_value(
        _FFOB_USE_SYSTEM_PACKAGES ${FOB_USE_SYSTEM_PACKAGES_OPTION})

    _fob_find_in_existing_packages(${_FFOB_USE_SYSTEM_PACKAGES}
        ${PACKAGE_NAME} "${_FFOB_UNPARSED_ARGUMENTS};${_FOB_CFG_ARGS_SETTING}")
    
    _fob_is_package_found(${PACKAGE_NAME} _FOB_PACKAGE_FOUND)
    if(NOT _FOB_PACKAGE_FOUND AND 
        NOT _FFOB_USE_SYSTEM_PACKAGES STREQUAL ALWAYS
        AND FOB_ENABLE_PACKAGE_RETRIEVE)
        message(STATUS "Unable to find ${PACKAGE_NAME}: Trying to build ...")

        _fob_download_build_install_package(
            ${PACKAGE_NAME} ${_FOB_FIND_PKG_VER_ARG} ${_FOB_CFG_ARGS_SETTING})

        _fob_find_package_ours_only(${PACKAGE_NAME}
            "${_FFOB_UNPARSED_ARGUMENTS};${_FOB_CFG_ARGS_SETTING}")
    endif()
endmacro(fob_find_or_build)
