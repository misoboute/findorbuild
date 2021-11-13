# This module is automatically included before any of the package retrieval 
# modules. The utility functions and macros defined here are to be used
# package retrieval modules.

# When any of the package retrieval modules are included they will have 
# access to the FOB_REQUESTED_VERSION (if the original fob_find_or_build 
# call contains a version) and other build customization parameters passed
# to the original fob_find_or_build through the CFG_ARGS argument.

# The package retrieval module is expected to be located at 
# ${FOB_REPO_ROOT}/cmake/retrievers/${PACKAGE_NAME}.cmake.

# When writing a new retrieve module, have an include guard at the top
# so that the module is not included twice.

# It is a also good idea to set default values for the version and other
# build config arguments after that. This could serve a document for the
# users of the package to know what arguments they could pass to 
# fob_find_or_build through CFG_ARGS.

# The next step is to add external project(s) that take care of download, 
# build, and install of the package based on the provided parameters.
# This can be done in two different ways depending on whether the package 
# features a build system that is CMake-based.

# For CMake-based packages, simply use the fob_add_ext_cmake_project to
# add the external project and its steps.

# For non-CMake-based packages, first, you need to manually invoke 
# fob_setup_extproj_dirs to create the directory hierarchy within the 
# FOB storage. Then you should directly use the the CMake ExternalProject
# module functions (e.g. ExternalProject_Add and ExternalProject_Add_Step) 
# to define the external project. You also need to manually call
# fob_write_specific_compatibility_file if any of the variables in the module
# (usually those defined at the top of the module and which could be defined
# customized by the CFG_ARGS argument of fob_find_or_build) could make the 
# build distinct, i.e. incompatible with the same library built with 
# different values for those variables.

# If your package needs specific compatibility checking by the finder, you
# will also need to create a the compatibility checker module template file.
# The template file is downloaded from the FOB repository during building of
# the package and configured using fob_write_specific_compatibility_file
# during a particularly customized build of the package to store the values
# of the build parameters. The configured file is included by 
# fob_find_or_build. It is expected to compare the find-time 
# values of the parameters with those stored in it when it is configured.
# If the find-time values of the parameters match or are compatible with those
# from the original package build, it is expected to set value of the variable
# FOB_IS_COMPATIBLE to true (or equivalent). Otherwise it should explicitly
# set the value of FOB_IS_COMPATIBLE to false (or equivalent).

# Take a look at existing package retrieval modules and their respective
# specific compatibility checker module templates (if applicable) or use 
# one of them as a starting template if you are creating a new retriever.

# Note: Macros, functions, and variables whose names begin with a single
# underscore are intended for internal module usage. Only use the macros and
# functions that begin with fob_ or variables that begin with FOB_ (without a
# leading underscore).

if(FOB_PACKAGE_UTILS_INCLUDED)
    return()
endif(FOB_PACKAGE_UTILS_INCLUDED)
set(FOB_PACKAGE_UTILS_INCLUDED 1)

include(FindOrBuild)
include(ExternalProject)

# Calculates the build description string. This string consists of a series of
# lines of the form NAME=VALUE. These name/value pairs together define a
# certain build configuration which might not be binary compatible with other
# build configurations. Names of CMake variables that affect distinction 
# among different builds are passed as input (BUILD_DISTINGUISHING_VARS) and
# the output string is placed in the variable named by DESC_VAR.
function(_calc_build_config_desc DESC_VAR BUILD_DISTINGUISHING_VARS)
    list(APPEND BUILD_DISTINGUISHING_VARS
        CMAKE_C_COMPILER_ID CMAKE_CXX_COMPILER_ID 
        CMAKE_SIZEOF_VOID_P CMAKE_SYSTEM_NAME
    )
    if(XCODE)
        list(APPEND BUILD_DISTINGUISHING_VARS
            XCODE_VERSION CMAKE_OSX_DEPLOYMENT_TARGET)
    elseif(MSVC)
        list(APPEND BUILD_DISTINGUISHING_VARS MSVC_TOOLSET_VERSION)
    endif()

    set(DESC)
    foreach(VAR ${BUILD_DISTINGUISHING_VARS})
        string(APPEND DESC "-D${VAR}=${${VAR}}\n")
    endforeach(VAR)

    set(${DESC_VAR} ${DESC} PARENT_SCOPE)
endfunction(_calc_build_config_desc)

# Computes a quasi-unique build configuration ID (placed in the variable 
# named by CFG_ID_VAR) based on the hash of the build configuration description
# which is, in turn, calculated from a set of CMake variables that affect 
# distinction among builds (BUILD_DISTINGUISHING_VARS) and the CMake 
# environment.
function(_calc_build_config_id CFG_ID_VAR BUILD_DISTINGUISHING_VARS)
    _calc_build_config_desc(CFG_DESC "${BUILD_DISTINGUISHING_VARS}")
    string(MD5 HASH ${CFG_DESC})
    string(SUBSTRING ${HASH} 0 10 HASH)
    set(${CFG_ID_VAR} ${HASH} PARENT_SCOPE)
endfunction(_calc_build_config_id)

# Downloads a FOB file from the upstream repository if it hasn't already 
# been downloaded. FILE_PATH is relative to the fob repository root.
# If successful and if PATH_OUT_VAR is provided, upon return, the given 
# variable will contain the full path to downloaded file within the build 
# directory. Pass the optional parameter NOWARN to disable the warning if
# the download fails.
function(fob_download_fob_file_if_not_exists FILE_PATH PATH_OUT_VAR)
    set(FOB_BINARY_ROOT_DIR ${CMAKE_BINARY_DIR}/fob)
    set(FOB_ROOT_DIR_URL
        https://raw.githubusercontent.com/misoboute/findorbuild/main)

    set(URL ${FOB_ROOT_DIR_URL}/${FILE_PATH})
    set(LOCAL_PATH ${FOB_BINARY_ROOT_DIR}/${FILE_PATH})
    
    if(NOT EXISTS ${LOCAL_PATH})
        file(DOWNLOAD ${URL} ${LOCAL_PATH} STATUS DL_STAT)
        list(POP_FRONT DL_STAT ERRNO)
        if(ERRNO)
            list(POP_FRONT DL_STAT MSG)
            if("NOWARN" IN_LIST ARGN)
                message(AUTHOR_WARNING
                    "Failed to download from ${URL} to ${LOCAL_PATH} => ${MSG}")
            endif()
            if(PATH_OUT_VAR)
                unset(${PATH_OUT_VAR} PARENT_SCOPE)
            endif()
        else()
            if(PATH_OUT_VAR)
                set(${PATH_OUT_VAR} ${LOCAL_PATH} PARENT_SCOPE)
            endif()
        endif()
    endif()
endfunction(fob_download_fob_file_if_not_exists)

# Write a human readable text file to the build configuration root directory
# (${FOB_STORAGE_ROOT}/${PACKAGE_NAME}/${PACKAGE_VERSION}/${CONFIG_HASH_ID})
# that can be viewed by users to examine the specific conditions in which
# the accompanying library has been built.
function(_write_build_config_desc_file CFG_DIR BUILD_DISTINGUISHING_VARS)
    _calc_build_config_desc(CFG_DESC "${BUILD_DISTINGUISHING_VARS}")
    string(PREPEND CFG_DESC
"Build system  and package build configuration:
===============================================\n")
    file(WRITE ${CFG_DIR}/BuildConfigDesc.txt ${CFG_DESC})
endfunction(_write_build_config_desc_file)

# Normalizes a version number, in the variable named by VERSION_VAR, by 
# converting it to n.n(.n(.n)) where n represents a natural number. If the 
# the input version has fewer than the required components, one or more 
# zero-valued components are appended to the version. The result will be 
# replaced in the same input variable. The required number of components can
# specified as the second argument. If not specified it is assumed to be 4.
function(fob_normalize_version_number VERSION_VAR)
    if(ARGC GREATER 1)
        set(NUM_COMPONENTS ${ARGV1})
    else()
        set(NUM_COMPONENTS 4)
    endif()
    if(NUM_COMPONENTS GREATER 4 OR NUM_COMPONENTS LESS 2)
        message(FATAL_ERROR
            "Invalid number of version components: ${NUM_COMPONENTS}")
    endif()
    set(VERSION ${${VERSION_VAR}})
    string(REPLACE "." ";" VERSION_PARTS ${VERSION})
    list(LENGTH VERSION_PARTS COUNT_VERSION_PARTS)
    math(EXPR COUNT_MISSING_VER_PARTS 
        "${NUM_COMPONENTS} - ${COUNT_VERSION_PARTS}")
    if(COUNT_MISSING_VER_PARTS GREATER 0)
        string(REPEAT ".0" ${COUNT_MISSING_VER_PARTS} MISSING_VER_PARTS)
    endif()
    set(${VERSION_VAR} "${VERSION}${MISSING_VER_PARTS}" PARENT_SCOPE)
endfunction(fob_normalize_version_number)

# Write the specific binary compatibility checker file to the location within
# the FOB storage where the build library is to be installed. It downloads
# the compatibility checker module template and the configures it using
# the current values of the variables and places it in the appropriate
# location within the build config directory (CFG_DIR) which is:
# ${FOB_STORAGE_ROOT}/${PACKAGE_NAME}/${PACKAGE_VERSION}/${CONFIG_HASH_ID}
# The compatibility checker module template is expected to be at
# ${FOB_REPOSITORY_ROOT}/compatibility/${MODULE_NAME}.in.cmake
# The output is written to ${CFG_DIR}/compatibility/${MODULE_NAME}.cmake.
# All optional parameters, including NOWARN, are forwarded to the underlying
# fob_download_fob_file_if_not_exists.
function(fob_write_specific_compatibility_file CFG_DIR MODULE_NAME)
    unset(INPUT_FILE)
    foreach(MOD_PATH ${CMAKE_MODULE_PATH})
        if(EXISTS ${MOD_PATH}/compatibility/${MODULE_NAME}.in.cmake)
            set(INPUT_FILE ${MOD_PATH}/compatibility/${MODULE_NAME}.in.cmake)
            break()
        endif()
    endforeach(MOD_PATH)
    if(NOT INPUT_FILE)
        fob_download_fob_file_if_not_exists(
            cmake/compatibility/${MODULE_NAME}.in.cmake INPUT_FILE ${ARGN})
    endif()
    if(INPUT_FILE)
        configure_file(
            ${INPUT_FILE} ${CFG_DIR}/compatibility/${MODULE_NAME}.cmake @ONLY)
    endif()
endfunction(fob_write_specific_compatibility_file)

# Creates the directory tree within the FOB store where package archives,
# sources, and multiple build/install trees (for each distinct configuration),
# and sets the variables CONFIG_ROOT_DIR, DOWNLOAD_DIR, SOURCE_DIR, TEMP_DIR, 
# STAMP_DIR, BINARY_DIR, LOG_DIR, INSTALL_DIR. These variables should be used
# by the retrieval modules to set them to the ExternalProject that they define.
macro(fob_setup_extproj_dirs NAME VERSION)
    set(_BUILD_DISTINGUISHING_VARS ${ARGN})
    _calc_build_config_id(CFG_ID "${_BUILD_DISTINGUISHING_VARS}")
    
    set(_VERSION ${VERSION})

    set(_BASE_DIR ${FOB_STORAGE_ROOT}/${NAME}/${_VERSION})
    set(CONFIG_ROOT_DIR ${_BASE_DIR}/${CFG_ID})

    set(DOWNLOAD_DIR ${_BASE_DIR}/download)
    set(SOURCE_DIR ${_BASE_DIR}/src)
    set(TEMP_DIR ${CONFIG_ROOT_DIR}/tmp)
    set(STAMP_DIR ${CONFIG_ROOT_DIR}/stamp)
    set(BINARY_DIR ${CONFIG_ROOT_DIR}/build)
    set(LOG_DIR ${CONFIG_ROOT_DIR}/log)
    set(INSTALL_DIR ${CONFIG_ROOT_DIR}/install)

    _write_build_config_desc_file(
        ${CONFIG_ROOT_DIR} "${_BUILD_DISTINGUISHING_VARS}")
    fob_write_specific_compatibility_file(${CONFIG_ROOT_DIR} Generic)
endmacro()

# If the generator is MSVC, it finds the corresponding vcvarsall.bat and
# stores the path in the output variable. It also appends appropriate arguments
# to the output variable according to the specified ARCH (target architecture)
# and HOST_ARCH (host architecture). If architecture is not specified, current
# architecture will be used for both host and target. Pass the STRING option
# to have the output as a single command line string rather than the usual
# ;-list used in cmake COMMAND arguments.
function(fob_find_vcvarsall OUTVAR)
    if(NOT MSVC)
        message(AUTHOR_WARNING "fob_find_vcvarsall only works with MSVC!")
        return()
    endif(NOT MSVC)

    set(OPTIONS REQUIRED STRING)
    set(SINGLE_VAL ARCH HOST_ARCH)
    set(MULTI_VAL)
    cmake_parse_arguments(
        ARG "${OPTIONS}" "${SINGLE_VAL}" "${MULTI_VAL}" ${ARGN})

    get_filename_component(_VC_LINKER_DIR ${CMAKE_LINKER} DIRECTORY)
    find_file(_VCVARSALL_BAT vcvarsall.bat
        ${_VC_LINKER_DIR}/..
        ${_VC_LINKER_DIR}/../..
        # MSVS2017 Community:
        ${_VC_LINKER_DIR}/../../../../../../Auxiliary/Build
        # MSVS2017 Enterprise, etc:
        ${_VC_LINKER_DIR}/../../../../../Auxiliary/Build
    )

    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(_CURRENT_ARCH amd64)
    else()
        set(_CURRENT_ARCH x86)
    endif()
    
    fob_set_default_var_value(ARG_ARCH ${_CURRENT_ARCH})
    fob_set_default_var_value(ARG_HOST_ARCH ${_CURRENT_ARCH})

    if(${ARG_ARCH} STREQUAL ${ARG_HOST_ARCH})
        set(_VCVARSALL_ARG ${ARG_ARCH})
    else(${ARG_ARCH} STREQUAL ${ARG_HOST_ARCH})
        set(_VCVARSALL_ARG ${ARG_HOST_ARCH}_${ARG_ARCH})
    endif(${ARG_ARCH} STREQUAL ${ARG_HOST_ARCH})

    if(ARG_STRING)
        string(REPLACE ";" " " _VCVARSALL_ARG ${_VCVARSALL_ARG})
        file(TO_NATIVE_PATH ${_VCVARSALL_BAT} _VCVARSALL_BAT)
        set(_VCVARS_CMD "CALL \"${_VCVARSALL_BAT}\" ${_VCVARSALL_ARG}")
    else(ARG_STRING)
        set(_VCVARS_CMD CALL ${_VCVARSALL_BAT} ${_VCVARSALL_ARG})
    endif(ARG_STRING)

    if(_VCVARSALL_BAT)
        set(${OUTVAR} ${_VCVARS_CMD} PARENT_SCOPE)
    else(_VCVARSALL_BAT)
        if (ARG_REQUIRED)
            message(FATAL_ERROR "Failed to locate vcvarsall.bat")
        endif ()
        unset(${OUTVAR} PARENT_SCOPE)
    endif(_VCVARSALL_BAT)
endfunction(fob_find_vcvarsall)

# Creates a Windows batch file that sets up MSVS development environment
# by invoking vcvarsall.bat, optionally sets VSCMD_START_DIR beforehand and
# switches to a specified working directory, and then executes the given
# piece of CODE.
# For the packages that require one or more of the steps to
# be run in an MSVS developer command prompt, this can be used to enclose
# those steps in a batch file that creates the same environment.
# vcvarsall.bat changes directory to a different path and the build
# might be messed up. VSCMD_START_DIR prevents this behaviour.
# https://stackoverflow.com/questions/46681881/visual-studio-2017-developer-command-prompt-switches-current-directory?rq=1
function(fob_run_under_vcdevcommand_env BATCH_FILE_PATH CODE)
    set(OPTIONS)
    set(SINGLE_VAL WORKING_DIR VSCMD_START_DIR)
    set(MULTI_VAL)
    cmake_parse_arguments(
        ARG "${OPTIONS}" "${SINGLE_VAL}" "${MULTI_VAL}" ${ARGN})

    set(BATCH_FILE_CONTENTS 
        "REM Auto-generated by fob_run_under_vcdevcommand_env\n")

    if(ARG_VSCMD_START_DIR)
        cmake_path(NATIVE_PATH ARG_VSCMD_START_DIR NORMALIZE START_DIR_NATIVE)
        string(APPEND BATCH_FILE_CONTENTS 
            "SET VSCMD_START_DIR=\"${START_DIR_NATIVE}\"\n")
    endif()

    fob_find_vcvarsall(VCVARSALL STRING REQUIRED)
    string(APPEND BATCH_FILE_CONTENTS "${VCVARSALL}\n")

    if(ARG_WORKING_DIR)
        cmake_path(NATIVE_PATH ARG_WORKING_DIR NORMALIZE WORKING_DIR_NATIVE)
        string(APPEND BATCH_FILE_CONTENTS "CD /D \"${WORKING_DIR_NATIVE}\"\n")
    endif()

    string(APPEND BATCH_FILE_CONTENTS "${CODE}\n")

    file(WRITE ${BATCH_FILE_PATH} "${BATCH_FILE_CONTENTS}")
endfunction(fob_run_under_vcdevcommand_env)

# Add an external project that sets up the package directory tree within
# FOB storage, writes the corresponding compatibility checker module,
# and adds the external project and its steps. NAME and VERSION specify 
# the source snapshot to retrieve. Use the BUILD_DISTINGUISHING_VARS argument
# to pass the names of the variables whose differing values make incompatible 
# built binaries. On MSVC, you can use the optional PDB_INSTALL_DIR argument 
# to specify a directory (relative to the install prefix) where compile 
# PDB files. All other arguments passed to this function are forwarded to 
# the underlying ExternalProject_Add.
function(fob_add_ext_cmake_project NAME VERSION)
    set(OPTIONS)
    set(SINGLE_VAL PDB_INSTALL_DIR)
    set(MULTI_VAL CMAKE_ARGS CMAKE_CACHE_ARGS CMAKE_CACHE_DEFAULT_ARGS 
        BUILD_DISTINGUISHING_VARS)
    cmake_parse_arguments(
        ARG "${OPTIONS}" "${SINGLE_VAL}" "${MULTI_VAL}" ${ARGN})

    fob_setup_extproj_dirs(${NAME} ${VERSION} ${ARG_BUILD_DISTINGUISHING_VARS})

    fob_write_specific_compatibility_file(${CONFIG_ROOT_DIR} ${NAME})

    if(MSVC AND ARG_PDB_INSTALL_DIR)
        set(PDB_OUT_DIR <BINARY_DIR>/PDBFilesDebug)
        set(_SPEC_PDB_OUTPUT_DIR
            -DCMAKE_COMPILE_PDB_OUTPUT_DIRECTORY_DEBUG:PATH=${PDB_OUT_DIR})
    else()
        set(_SPEC_PDB_OUTPUT_DIR)
    endif()
    
    ExternalProject_Add(
        FOB_${NAME}
        DOWNLOAD_DIR ${DOWNLOAD_DIR}
        SOURCE_DIR ${SOURCE_DIR}
        BINARY_DIR ${BINARY_DIR}
        TMP_DIR ${TEMP_DIR}
        STAMP_DIR ${STAMP_DIR}
        LOG_DIR ${LOG_DIR}
        INSTALL_DIR ${INSTALL_DIR}
        BUILD_COMMAND ""	# Multiple custom commands are added instead for
        INSTALL_COMMAND ""	# each optimization configuration
        CMAKE_ARGS 
            ${ARG_CMAKE_ARGS}
        CMAKE_CACHE_ARGS
            ${ARG_CMAKE_CACHE_ARGS}
            -DCMAKE_INSTALL_PREFIX:STRING=<INSTALL_DIR>
            -DCMAKE_C_COMPILER:PATH=${CMAKE_C_COMPILER}
            -DCMAKE_CXX_COMPILER:PATH=${CMAKE_CXX_COMPILER}
            -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET}
            "-DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}"
            -DCMAKE_DEBUG_POSTFIX:STRING=d
            -DCMAKE_RELWITHDEBINFO_POSTFIX:STRING=rd
            -DCMAKE_MINSIZEREL_POSTFIX:STRING=mr
            ${_SPEC_PDB_OUTPUT_DIR}
        CMAKE_CACHE_DEFAULT_ARGS ${ARG_CMAKE_CACHE_DEFAULT_ARGS}
        ${ARG_UNPARSED_ARGUMENTS}
    )

    if(NOT CMAKE_CONFIGURATION_TYPES)
        if(NOT CMAKE_BUILD_TYPE)
            set(OPT_CFG_TYPES Release)
        else()
            set(OPT_CFG_TYPES ${CMAKE_BUILD_TYPE})
        endif()
    else()
        set(OPT_CFG_TYPES ${CMAKE_CONFIGURATION_TYPES})
    endif()

    foreach(CFG ${OPT_CFG_TYPES})
        ExternalProject_Add_Step(FOB_${NAME} build_${CFG}
            COMMENT "Building ${NAME} - ${CFG}"
            COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --config ${CFG}
            DEPENDEES configure
            DEPENDERS build
        )
        ExternalProject_Add_Step(FOB_${NAME} install_${CFG}
            COMMENT "Installing ${NAME} - ${CFG}"
            COMMAND ${CMAKE_COMMAND}
                --build <BINARY_DIR> --target install --config ${CFG}
            DEPENDEES build
            DEPENDERS install
        )
    endforeach(CFG)

    if(MSVC AND ARG_PDB_INSTALL_DIR)
        if(NOT IS_ABSOLUTE ${ARG_PDB_INSTALL_DIR})
            set(ARG_PDB_INSTALL_DIR <INSTALL_DIR>/${ARG_PDB_INSTALL_DIR})
        endif()
        ExternalProject_Add_Step(FOB_${NAME} install_pdbs
            COMMENT "Installing ${NAME} debug PDBs"
            COMMAND ${CMAKE_COMMAND} -E
                copy_directory ${PDB_OUT_DIR} ${ARG_PDB_INSTALL_DIR}
            DEPENDEES build
            DEPENDERS install
        )
    endif()
endfunction(fob_add_ext_cmake_project)
