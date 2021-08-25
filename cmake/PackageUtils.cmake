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

function(fob_add_ext_cmake_project NAME VERSION)
    set(OPTIONS)
    set(SINGLE_VAL PDB_INSTALL_DIR CONFIG_FILE_INSTALL_DIR)
    set(MULTI_VAL CMAKE_ARGS CMAKE_CACHE_ARGS CMAKE_CACHE_DEFAULT_ARGS 
        BUILD_DISTINGUISHING_VARS)
    cmake_parse_arguments(
        ARG "${OPTIONS}" "${SINGLE_VAL}" "${MULTI_VAL}" ${ARGN})
        
    _calc_build_config_id(CFG_ID "${ARG_BUILD_DISTINGUISHING_VARS}")
    fob_normalize_version_number(VERSION)

    set(BASE_DIR ${FOB_STORAGE_ROOT}/${NAME}/${VERSION})
    set(CFG_DIR ${BASE_DIR}/${CFG_ID})

    _write_build_config_desc_file(${CFG_DIR} "${ARG_BUILD_DISTINGUISHING_VARS}")

    set(DOWNLOAD_DIR ${BASE_DIR}/download)
    set(SOURCE_DIR ${BASE_DIR}/src)
    set(TMP_DIR ${CFG_DIR}/tmp)
    set(STAMP_DIR ${CFG_DIR}/stamp)
    set(BINARY_DIR ${CFG_DIR}/build)
    set(LOG_DIR ${CFG_DIR}/log)
    set(INSTALL_DIR ${CFG_DIR}/install)

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
            "-DCMAKE_CONFIGURATION_TYPES:STRING=${EXT_PROJ_CONFIGS}"
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
