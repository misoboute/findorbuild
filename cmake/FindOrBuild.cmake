if(FOB_FIND_OR_BUILD_INCLUDED)
    return()
endif(FOB_FIND_OR_BUILD_INCLUDED)
set(FOB_FIND_OR_BUILD_INCLUDED 1)

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
    set(_FOB_DEFAULT_PACKAGE_ROOT $ENV{FOB_STORAGE_ROOT})
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
    TRUE)

include(${FOB_MODULE_DIR}/CommonUtils.cmake)

function(_does_cfg_dir_match_args OUT_VAR CFG_DIR CFG_ARGS)
    file(STRINGS ${CFG_DIR}/BuildConfigDesc.txt CONFIG_DESC)
    foreach(REQUIRED_CFG ${CFG_ARGS})
        set(ARG_REGEX "^-D\\s*([a-zA-Z_][0-9a-zA-Z_]*)=(.*)")
        set(REQ_ITEM_MET false)
        if(REQUIRED_CFG MATCHES ${ARG_REGEX})
            set(REQUIRED_ARG_NAME ${CMAKE_MATCH_0})
            set(REQUIRED_ARG_VALUE ${CMAKE_MATCH_1})
            foreach(ACTUAL_CFG {CONFIG_DESC})
                if(ACTUAL_CFG MATCHES ${ARG_REGEX})
                    set(ACTUAL_ARG_NAME ${CMAKE_MATCH_0})
                    set(ACTUAL_ARG_VALUE ${CMAKE_MATCH_1})
                    if(ACTUAL_ARG_NAME STREQUAL REQUIRED_ARG_NAME
                            AND ACTUAL_ARG_VALUE STREQUAL REQUIRED_ARG_VALUE)
                        set(REQ_ITEM_MET true)
                        break()
                    endif()
                endif()
            endforeach(ACTUAL_CFG)
        endif()
        if(NOT REQ_ITEM_MET)
            set(${OUT_VAR} false PARENT_SCOPE)
            return()
        endif()
    endforeach(REQUIRED_CFG)
    set(${OUT_VAR} true PARENT_SCOPE)
endfunction(_does_cfg_dir_match_args)

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
    if(CFG_ARGS)
        set(MATCHING_CFG_DIRS)
        foreach(CFG_DIR ${CONFIG_DIRS})
            _does_cfg_dir_match_args(IS_MATCH CFG_DIR ${CFG_ARGS})
            if(IS_MATCH)
                list(APPEND MATCHING_CFG_DIRS ${CFG_DIR})
            endif()
        endforeach(CFG_DIR)
    else()
        set(MATCHING_CFG_DIRS ${CONFIG_DIRS})
    endif()
    list(TRANSFORM MATCHING_CFG_DIRS APPEND /install)
    file(GLOB INSTALL_DIRS LIST_DIRECTORIES true ${MATCHING_CFG_DIRS})
    set(${PATHS_VAR} ${INSTALL_DIRS} PARENT_SCOPE)
endfunction(_get_all_paths_for_package_in_fob_storage)

macro(_fob_find_package_ours_only PACKAGE_NAME FIND_ARGS)
    set(_FOB_OPTIONS)
    set(_FOB_SINGLE_VAL)
    set(_FOB_MULTI_VAL CFG_ARGS)
    cmake_parse_arguments(_FOBARG 
        "${_FOB_OPTIONS}" "${_FOB_SINGLE_VAL}" "${_FOB_MULTI_VAL}" ${ARGN})

    if(_FOBARG_CFG_ARGS)
        set(_FOB_CFG_ARGS_SETTING CFG_ARGS ${_FOBARG_CFG_ARGS})
    else()
        unset(_FOB_CFG_ARGS_SETTING)
    endif()

    fob_push_var(CMAKE_FIND_FRAMEWORK)
    fob_push_var(CMAKE_FIND_APPBUNDLE)
    set(CMAKE_FIND_FRAMEWORK LAST)
    set(CMAKE_FIND_APPBUNDLE LAST)
    _get_all_paths_for_package_in_fob_storage(
        ${PACKAGE_NAME} PKG_PATHS ${_FOB_CFG_ARGS_SETTING})
    find_package("${FIND_ARGS}" NO_DEFAULT_PATH PATHS ${PKG_PATHS})
    fob_pop_var(CMAKE_FIND_FRAMEWORK)
    fob_pop_var(CMAKE_FIND_APPBUNDLE)
endmacro(_fob_find_package_ours_only)

macro(_fob_find_package_first_attempt USE_SYS_PACKAGES PACKAGE_NAME FIND_ARGS)
    if (${USE_SYS_PACKAGES} STREQUAL FIRST OR 
            ${USE_SYS_PACKAGES} STREQUAL ALWAYS)
        find_package(${PACKAGE_NAME} "${FIND_ARGS}")
    else ()
        _fob_find_package_ours_only(${PACKAGE_NAME} "${FIND_ARGS}")
    endif()
endmacro(_fob_find_package_first_attempt)

macro(_fob_find_package_second_attempt USE_SYS_PACKAGES PACKAGE_NAME FIND_ARGS)
    if (${USE_SYS_PACKAGES} STREQUAL LAST OR 
            ${USE_SYS_PACKAGES} STREQUAL ALWAYS)
        find_package(${PACKAGE_NAME} "${FIND_ARGS}")
    else ()
        _fob_find_package_ours_only(${PACKAGE_NAME} "${FIND_ARGS}")
    endif()
endmacro(_fob_find_package_second_attempt)

macro(_fob_find_in_existing_packages USE_SYS_PACKAGES PACKAGE_NAME FIND_ARGS)
    # First we need to see if the package can be found, so if a REQUIRED clause
    # is present, we remove it for the time being so the call doesn't fail.
    set(_FOB_MODIFIED_ARGS ${FIND_ARGS})
    if (NOT ${USE_SYS_PACKAGES} STREQUAL ALWAYS AND FOB_ENABLE_PACKAGE_RETRIEVE)
        list(REMOVE_ITEM _FOB_MODIFIED_ARGS REQUIRED)
    endif()
    
    _fob_find_package_first_attempt(
        ${USE_SYS_PACKAGES} ${PACKAGE_NAME} "${_FOB_MODIFIED_ARGS}")

    if (${USE_SYS_PACKAGES} STREQUAL FIRST OR ${USE_SYS_PACKAGES} STREQUAL LAST)
        _fob_find_package_second_attempt(
            ${USE_SYS_PACKAGES} ${PACKAGE_NAME} "${_FOB_MODIFIED_ARGS}")
    endif()    
endmacro(_fob_find_in_existing_packages)

function(_fob_is_package_found PACKAGE_NAME OUTPUT_VAR)
    # Some CMake find modules set the <UPPERCASE_PACKAGE_NAME>_FOUND variable
    # even if the package name passed to find_package is not in all uppercase.
    string(TOUPPER ${PACKAGE_NAME} _UPPERCASE_PACKAGE_NAME)
    if (${PACKAGE_NAME}_FOUND OR ${_UPPERCASE_PACKAGE_NAME}_FOUND)
        set(${OUTPUT_VAR} TRUE PARENT_SCOPE)
    else()
        set(${OUTPUT_VAR} FALSE PARENT_SCOPE)
    endif()
endfunction(_fob_is_package_found)

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
function(_fob_convert_cmdln_cache_args_to_cache_preloader
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
\"Generated by _fob_convert_cmdln_cache_args_to_cache_preloader\" FORCE)\n")

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

endfunction(_fob_convert_cmdln_cache_args_to_cache_preloader)

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
    else()
        string(REPLACE ";" " " MODULES_SPACE_SEP "${ARG_MODULES}")
    endif()

    set(LIST_FILE_CONTENTS
"cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})
${PROJECT_LINE}
set(CMAKE_MODULE_PATH \"${FOB_MODULE_DIR}\")
include(\${FOB_MODULE_DIR}/PackageUtils.cmake)
foreach(MOD ${MODULES_SPACE_SEP})
    include(\${MOD})
endforeach(MOD)
")

    if(NOT ARG_PROJ_PATH)
        string(RANDOM LENGTH 8 ARG_PROJ_PATH)
    endif(NOT ARG_PROJ_PATH)
    file(WRITE ${ARG_PROJ_PATH}/CMakeLists.txt ${LIST_FILE_CONTENTS})

    _fob_convert_cmdln_cache_args_to_cache_preloader(
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

function(_fob_download_build_install_package PACKAGE_NAME)
    set(OPTIONS)
    set(SINGLE_VAL)
    set(MULTI_VAL CFG_ARGS)
    cmake_parse_arguments(
        ARG "${OPTIONS}" "${SINGLE_VAL}" "${MULTI_VAL}" ${ARGN})

    set(EXT_PROJ_PATH ${CMAKE_BINARY_DIR}/fob/ExtProj/${PACKAGE_NAME})
    file(REMOVE_RECURSE ${EXT_PROJ_PATH})

    list(GET ARG_UNPARSED_ARGUMENTS 0 FIND_PKG_VER_ARG)
    if (FIND_PKG_VER_ARG VERSION_GREATER 0)
        set(REQUESTED_VER_CACHE_SETTING
            "-DFOB_REQUESTED_VERSION:STRING=${FIND_PKG_VER_ARG}")
    else ()
        set(REQUESTED_VER_CACHE_SETTING)
    endif ()

    if (ARG_CFG_ARGS)
        set(REQUESTED_CFG_ARGS_SETTING
            "-DREQUESTED_CFG_ARGS:STRING=${REQUESTED_CFG_ARGS}")
    else ()
        set(REQUESTED_CFG_ARGS_SETTING)
    endif ()

    _download_fob_module_if_not_exists(FOB-Retrieve-${PACKAGE_NAME})

    _fob_include_and_build_in_cmake_time(
        PROJ_NAME Retrieve${PACKAGE_NAME}
        MODULES FOB-Retrieve-${PACKAGE_NAME}
        PROJ_PATH ${EXT_PROJ_PATH}
        CACHE_ARGS
            -DFOB_MODULE_DIR=${FOB_MODULE_DIR}
            -DFOB_STORAGE_ROOT=${FOB_STORAGE_ROOT}
            "-DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}"
            "-DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}"
            "-DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}"
            -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET}
            "-DCMAKE_CONFIGURATION_TYPES:STRING=${CMAKE_CONFIGURATION_TYPES}"
            ${REQUESTED_VER_CACHE_SETTING}
            ${REQUESTED_CFG_ARGS_SETTING}
    )
endfunction(_fob_download_build_install_package)

# We shall use this macro to find a package instead of plain find_package.
# Its syntax is identical to that of find_package.
# It calls the find_package and if the package cannot be found, or if the
# found package include directories are not in the SMUtil third party
# install directory, it includes the relevant module for downloading, building,
# and installing of the package.
macro(fob_find_or_build PACKAGE_NAME)
    set(_FOB_OPTIONS)
    set(_FOB_SINGLE_VAL USE_SYSTEM_PACKAGES)
    set(_FOB_MULTI_VAL CFG_ARGS)
    cmake_parse_arguments(_FOBARG
        "${_FOB_OPTIONS}" "${_FOB_SINGLE_VAL}" "${_FOB_MULTI_VAL}" ${ARGN})

    if(CFG_ARGS)
        set(_FOBARG_USE_SYSTEM_PACKAGES NEVER)
    endif()

    fob_set_default_var_value(
        _FOBARG_USE_SYSTEM_PACKAGES ${FOB_USE_SYSTEM_PACKAGES_OPTION})

    _fob_find_in_existing_packages(${_FOBARG_USE_SYSTEM_PACKAGES}
        ${PACKAGE_NAME} "${_FOBARG_UNPARSED_ARGUMENTS}")
    
    _fob_is_package_found(${PACKAGE_NAME} _FOB_PACKAGE_FOUND)
    if(NOT _FOB_PACKAGE_FOUND)
        message(STATUS "Unable to find ${PACKAGE_NAME}: Trying to build ...")

        if (_FOBARG_CFG_ARGS)
            set(_FOB_CFG_ARGS_SETTING CFG_ARGS ${_FOBARG_CFG_ARGS})
        else ()
            unset(_FOB_CFG_ARGS_SETTING)
        endif ()

        _fob_download_build_install_package(
            ${PACKAGE_NAME} ${_FOB_CFG_ARGS_SETTING})

        _fob_find_in_existing_packages(NEVER ${PACKAGE_NAME}
            ${_FOB_CFG_ARGS_SETTING} "${_FOBARG_UNPARSED_ARGUMENTS}")
    endif()
endmacro(fob_find_or_build)
