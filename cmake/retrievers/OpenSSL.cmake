if(FOB_RETRIEVE_OPENSSL_INCLUDED)
    return()
endif(FOB_RETRIEVE_OPENSSL_INCLUDED)
set(FOB_RETRIEVE_OPENSSL_INCLUDED 1)

fob_set_default_var_value(FOB_REQUESTED_VERSION 3.0.5)

fob_normalize_version_number(FOB_REQUESTED_VERSION 3)
set(VERSION_GIT_TAG openssl-${FOB_REQUESTED_VERSION})

fob_setup_extproj_dirs(OpenSSL ${FOB_REQUESTED_VERSION})

fob_write_specific_compatibility_file(${CONFIG_ROOT_DIR} OpenSSL)

cmake_path(APPEND INSTALL_DIR ssl OUTPUT_VARIABLE OPENSSL_DIR)
cmake_path(APPEND INSTALL_DIR lib OUTPUT_VARIABLE LIB_DIR)
if(WIN32)
    fob_find_or_build(Perl REQUIRED)
    set(OPENSSL_CONFIG_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/openssl-config.bat)
    set(OPENSSL_MAKE_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/openssl-build.bat)
    cmake_path(NATIVE_PATH INSTALL_DIR NORMALIZE INSTALL_DIR_NATIVE)
    cmake_path(NATIVE_PATH OPENSSL_DIR NORMALIZE OPENSSL_DIR_NATIVE)
    cmake_path(NATIVE_PATH LIB_DIR NORMALIZE LIB_DIR_NATIVE)
    
    fob_run_under_vcdevcommand_env(${OPENSSL_CONFIG_COMMAND}
        "${PERL_EXECUTABLE} Configure -v --prefix=\"${INSTALL_DIR_NATIVE}\""
        WORKING_DIR ${SOURCE_DIR}
        VSCMD_START_DIR ${SOURCE_DIR}
    )
    fob_run_under_vcdevcommand_env(${OPENSSL_MAKE_COMMAND} "nmake %1"
        WORKING_DIR ${SOURCE_DIR} VSCMD_START_DIR ${SOURCE_DIR})
elseif(UNIX)
    # On Linux, the FIND_LIBRARY_USE_LIB64_PATHS is false so the FindOpenSSL
    # module won't find the libraries that OpenSSL installs under lib64 by
    # default.
    set(OPENSSL_CONFIG_COMMAND 
        <SOURCE_DIR>/Configure -v --prefix=<INSTALL_DIR> --libdir=lib)
    set(OPENSSL_MAKE_COMMAND ${CMAKE_MAKE_PROGRAM})
endif()

ExternalProject_Add(
    FOB_OpenSSL
    GIT_REPOSITORY https://github.com/openssl/openssl.git
    GIT_TAG ${VERSION_GIT_TAG}
    GIT_SHALLOW true
    GIT_PROGRESS true
    DOWNLOAD_DIR ${DOWNLOAD_DIR}
    SOURCE_DIR ${SOURCE_DIR}
    BINARY_DIR ${BINARY_DIR}
    INSTALL_DIR ${INSTALL_DIR}
    TMP_DIR  ${TEMP_DIR}
    STAMP_DIR  ${STAMP_DIR}
    LOG_DIR  ${LOG_DIR}
    CONFIGURE_COMMAND ${OPENSSL_CONFIG_COMMAND}
    BUILD_COMMAND ${OPENSSL_MAKE_COMMAND}
    INSTALL_COMMAND ${OPENSSL_MAKE_COMMAND} install
)
