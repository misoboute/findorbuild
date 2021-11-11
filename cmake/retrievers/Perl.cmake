if(FOB_RETRIEVE_PERL_INCLUDED)
    return()
endif(FOB_RETRIEVE_PERL_INCLUDED)
set(FOB_RETRIEVE_PERL_INCLUDED 1)

if(CMAKE_SCRIPT_MODE_FILE)
    # The script mode is used to patch the Makefile as part of the 
    # configure step of the build. It sets the INST_DRV, INST_TOP, and CCTYPE
    # variables in the Makefile.

    # file(COPY_FILE ${MAKEFILE_PATH} ${MAKEFILE_PATH}.bk) 
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

fob_set_default_var_value(FOB_REQUESTED_VERSION 5.35.5)

fob_normalize_version_number(FOB_REQUESTED_VERSION 3)
set(VERSION_GIT_TAG v${FOB_REQUESTED_VERSION})

fob_setup_extproj_dirs(Perl ${FOB_REQUESTED_VERSION})

if(MSVC)
    fob_find_vcvarsall(VCVARSALL STRING REQUIRED)
    cmake_path(SET MAKE_DIR ${SOURCE_DIR}/win32)
    cmake_path(NATIVE_PATH MAKE_DIR NORMALIZE MAKE_DIR_NATIVE)
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/make_run.bat
"SET VSCMD_START_DIR=${MAKE_DIR_NATIVE}
${VCVARSALL}
CD \"${MAKE_DIR_NATIVE}\"
nmake %1"
    )
    cmake_path(SET MAKEFILE_PATH ${MAKE_DIR}/Makefile)
    set(MAKE_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/make_run.bat)
    set(MAKE_INSTALL_COMMAND ${MAKE_COMMAND} install)
else()
    set(MAKE_COMMAND "")
    set(MAKE_INSTALL_COMMAND "")
endif()

ExternalProject_Add(
    FOB_Perl
    GIT_REPOSITORY https://github.com/Perl/perl5.git
    GIT_TAG ${VERSION_GIT_TAG}
    GIT_SHALLOW true
    GIT_PROGRESS true
    DOWNLOAD_DIR ${DOWNLOAD_DIR}
    SOURCE_DIR ${SOURCE_DIR}
    BINARY_DIR ${BINARY_DIR}
    TMP_DIR ${TEMP_DIR}
    STAMP_DIR ${STAMP_DIR}
    LOG_DIR ${LOG_DIR}
    INSTALL_DIR ${INSTALL_DIR}
    CONFIGURE_COMMAND ${CMAKE_COMMAND}
        -DMAKEFILE_PATH=${MAKEFILE_PATH} -DINSTALL_DIR=${INSTALL_DIR} 
        -DMSVC_TOOLSET_VERSION=${MSVC_TOOLSET_VERSION}
        -P ${CMAKE_CURRENT_LIST_FILE}
    BUILD_COMMAND ${MAKE_COMMAND}
    INSTALL_COMMAND ${MAKE_INSTALL_COMMAND}
)
