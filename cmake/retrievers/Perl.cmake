if(FOB_RETRIEVE_PERL_INCLUDED)
    return()
endif(FOB_RETRIEVE_PERL_INCLUDED)
set(FOB_RETRIEVE_PERL_INCLUDED 1)

if(CMAKE_SCRIPT_MODE_FILE)
    # The script mode is used to patch the Makefile as part of the 
    # configure step of the build. It sets the INST_DRV, INST_TOP, and CCTYPE
    # variables in the Makefile.

    file(COPY_FILE ${MAKEFILE_PATH} ${MAKEFILE_PATH}.bk) 
    file(READ ${MAKEFILE_PATH} MAKEFILE_CONTENTS)

    set(PERL_MSVCVER "MSVC${MSVC_TOOLSET_VERSION}")
    string(REGEX REPLACE "#(CCTYPE[ \t\r\n]*=[ \t\r\n]*${PERL_MSVCVER})"
       "\\1" MAKEFILE_CONTENTS "${MAKEFILE_CONTENTS}")

    cmake_path(GET INSTALL_DIR ROOT_NAME INST_DRV)
    string(REGEX REPLACE "(INST_DRV[ \t\r\n]*=[ \t\r\n]*)[A-Za-z]:"
       "\\1${INST_DRV}" MAKEFILE_CONTENTS "${MAKEFILE_CONTENTS}")

    cmake_path(GET INSTALL_DIR RELATIVE_PART PERL_INST_TOP)
    cmake_path(NATIVE_PATH PERL_INST_TOP NORMALIZE PERL_INST_TOP)
    string(REPLACE "\\" "\\\\" PERL_INST_TOP ${PERL_INST_TOP})

    string(REGEX REPLACE
        "(INST_TOP[ \t\r\n]*=[ \t\r\n]*\\$\\(INST_DRV\\)\\\\)perl"
        "\\1${PERL_INST_TOP}" MAKEFILE_CONTENTS "${MAKEFILE_CONTENTS}")

    file(WRITE ${MAKEFILE_PATH} "${MAKEFILE_CONTENTS}")
    return()
endif()

fob_set_default_var_value(FOB_REQUESTED_VERSION 5.34.0)

fob_normalize_version_number(FOB_REQUESTED_VERSION 3)
set(VERSION_GIT_TAG v${FOB_REQUESTED_VERSION})

fob_setup_extproj_dirs(Perl ${FOB_REQUESTED_VERSION})

if(MSVC)
    cmake_path(SET MAKE_DIR ${SOURCE_DIR}/win32)
    cmake_path(SET MAKEFILE_PATH ${MAKE_DIR}/Makefile)
    set(PERL_CONFIG_CMD ${CMAKE_COMMAND}
        -DMAKEFILE_PATH=${MAKEFILE_PATH} -DINSTALL_DIR=<INSTALL_DIR>
        -DMSVC_TOOLSET_VERSION=${MSVC_TOOLSET_VERSION}
        -P ${CMAKE_CURRENT_LIST_FILE}
    )
    set(MAKE_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/make_run.bat)
    fob_run_under_vcdevcommand_env(${MAKE_COMMAND} "nmake %1"
        WORKING_DIR ${MAKE_DIR} VSCMD_START_DIR ${MAKE_DIR})
elseif(UNIX)
    set(PERL_CONFIG_CMD <SOURCE_DIR>/Configure -des -Dprefix=<INSTALL_DIR>)
    set(MAKE_COMMAND ${CMAKE_MAKE_PROGRAM})
endif()

ExternalProject_Add(
    FOB_Perl
    GIT_REPOSITORY https://github.com/Perl/perl5.git
    GIT_TAG ${VERSION_GIT_TAG}
    GIT_SHALLOW true
    GIT_PROGRESS true
    DOWNLOAD_DIR ${DOWNLOAD_DIR}
    SOURCE_DIR ${SOURCE_DIR}
    TMP_DIR ${TEMP_DIR}
    STAMP_DIR ${STAMP_DIR}
    LOG_DIR ${LOG_DIR}
    INSTALL_DIR ${INSTALL_DIR}
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND ${PERL_CONFIG_CMD}
    BUILD_COMMAND ${MAKE_COMMAND}
    INSTALL_COMMAND ${MAKE_COMMAND} install
)
