if(FOB_PACKAGE_UTILS_INCLUDED)
    return()
endif(FOB_PACKAGE_UTILS_INCLUDED)
set(FOB_PACKAGE_UTILS_INCLUDED 1)

include(${FOB_MODULE_DIR}/CommonUtils.cmake)
include(ExternalProject)

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
# directory.
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
            message(AUTHOR_WARNING
                "Failed to download from ${URL} to ${LOCAL_PATH} => ${MSG}")
            if(PATH_OUT_VAR)
                unset(${PATH_OUT_VAR})
            endif()
        else()
            if(PATH_OUT_VAR)
                set(${PATH_OUT_VAR} ${LOCAL_PATH})
            endif()
        endif()
    endif()
endfunction(fob_download_fob_file_if_not_exists)

function(_write_build_config_desc_file CFG_DIR BUILD_DISTINGUISHING_VARS)
    _calc_build_config_desc(CFG_DESC "${BUILD_DISTINGUISHING_VARS}")
    string(PREPEND CFG_DESC
"Build system  and package build configuration:
===============================================\n")
    file(WRITE ${CFG_DIR}/BuildConfigDesc.txt ${CFG_DESC})
endfunction(_write_build_config_desc_file)

function(fob_normalize_version_number VERSION_VAR)
    set(VERSION ${${VERSION_VAR}})
    string(REPLACE "." ";" VERSION_PARTS ${VERSION})
    list(LENGTH VERSION_PARTS COUNT_VERSION_PARTS)
    math(EXPR COUNT_MISSING_VER_PARTS "4 - ${COUNT_VERSION_PARTS}")
    string(REPEAT ".0" ${COUNT_MISSING_VER_PARTS} MISSING_VER_PARTS)
    set(${VERSION_VAR} "${VERSION}${MISSING_VER_PARTS}" PARENT_SCOPE)
endfunction(fob_normalize_version_number)

function(fob_write_specific_compatibility_file CFG_DIR MODULE_NAME)
    fob_download_fob_file_if_not_exists(
        ConfigCompatFiles/${MODULE_NAME}.in.cmake INPUT_FILE)
    configure_file(
        ${INPUT_FILE} ${CFG_DIR}/compatibility/${MODULE_NAME}.cmake @ONLY)
endfunction(fob_write_specific_compatibility_file)

# Creates the directory tree within the FOB store where package archives,
# sources, and multiple build/install trees (for each distinct configuration),
# and sets the variables CONFIG_ROOT_DIR, DOWNLOAD_DIR, SOURCE_DIR, TEMP_DIR, 
# STAMP_DIR, BINARY_DIR, LOG_DIR, INSTALL_DIR.
macro(fob_setup_extproj_dirs NAME VERSION)
    set(_BUILD_DISTINGUISHING_VARS ${ARGN})
    _calc_build_config_id(CFG_ID "${_BUILD_DISTINGUISHING_VARS}")
    
    set(_VERSION ${VERSION})
    fob_normalize_version_number(_VERSION)

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
        ${_CFG_DCONFIG_ROOT_DIRIR} "${_BUILD_DISTINGUISHING_VARS}")
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

    message("_VCVARSALL_BAT: ${_VCVARSALL_BAT}")
    if(_VCVARSALL_BAT)
        set(${OUTVAR} ${_VCVARS_CMD} PARENT_SCOPE)
    else(_VCVARSALL_BAT)
        if (ARG_REQUIRED)
            message(FATAL_ERROR "Failed to locate vcvarsall.bat")
        endif ()
        unset(${OUTVAR} PARENT_SCOPE)
    endif(_VCVARSALL_BAT)
endfunction(fob_find_vcvarsall)

function(fob_add_ext_cmake_project NAME VERSION)
    set(OPTIONS)
    set(SINGLE_VAL PDB_INSTALL_DIR)
    set(MULTI_VAL CMAKE_ARGS CMAKE_CACHE_ARGS CMAKE_CACHE_DEFAULT_ARGS 
        BUILD_DISTINGUISHING_VARS)
    cmake_parse_arguments(
        ARG "${OPTIONS}" "${SINGLE_VAL}" "${MULTI_VAL}" ${ARGN})

    fob_setup_extproj_dirs(${NAME} ${VERSION} ${BUILD_DISTINGUISHING_VARS})

    if(MSVC AND ARG_PDB_INSTALL_DIR)
        set(PDB_OUT_DIR <BINARY_DIR>/PDBFilesDebug)
        set(_SPEC_PDB_OUTPUT_DIR
            -DCMAKE_COMPILE_PDB_OUTPUT_DIRECTORY_DEBUG:PATH=${PDB_OUT_DIR})
    else()
        set(_SPEC_PDB_OUTPUT_DIR)
    endif()

    list(APPEND CMAKE_CACHE_ARGS
        -DCMAKE_INSTALL_PREFIX:STRING=<INSTALL_DIR>
        -DCMAKE_C_COMPILER:PATH=${CMAKE_C_COMPILER}
        -DCMAKE_CXX_COMPILER:PATH=${CMAKE_CXX_COMPILER}
        "-DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}"
        -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET}
        ${_SPEC_PDB_OUTPUT_DIR}
    )

    ExternalProject_Add(
        FOB_${NAME}
        DOWNLOAD_DIR ${DOWNLOAD_DIR}
        SOURCE_DIR ${SOURCE_DIR}
        BINARY_DIR ${BINARY_DIR}
        TMP_DIR ${TMP_DIR}
        STAMP_DIR ${STAMP_DIR}
        LOG_DIR ${LOG_DIR}
        INSTALL_DIR ${INSTALL_DIR}
        BUILD_COMMAND ""	# Multiple custom commands are added instead for
        INSTALL_COMMAND ""	# each optimization configuration
        CMAKE_ARGS 
            ${CMAKE_ARGS}
        CMAKE_CACHE_ARGS ${CMAKE_CACHE_ARGS}
            -DCMAKE_INSTALL_PREFIX:STRING=<INSTALL_DIR>
            -DCMAKE_C_COMPILER:PATH=${CMAKE_C_COMPILER}
            -DCMAKE_CXX_COMPILER:PATH=${CMAKE_CXX_COMPILER}
            -DCMAKE_DEBUG_POSTFIX:STRING=d
            -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET}
            "-DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}"
            ${REQUESTED_CFG_ARGS_SETTING}
        CMAKE_CACHE_DEFAULT_ARGS ${CMAKE_CACHE_DEFAULT_ARGS}
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
