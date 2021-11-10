# NOTE: Qt configure script stores system configuration state in cache variables
# so it won't have to compute them on every run. If the configure/build fails
# and you change some system configuration (install libraries, etc) to fix
# the issue and the configure/build still fails, it might be better to delete
# the current build directory (${BINARY_DIR} set by fob_setup_extproj_dirs)
# and try again. This is especially the case for missing features.

if(FOB_RETRIEVE_PERL_INCLUDED)
    return()
endif(FOB_RETRIEVE_PERL_INCLUDED)
set(FOB_RETRIEVE_PERL_INCLUDED 1)

fob_set_default_var_value(FOB_REQUESTED_VERSION 5.35.5)

fob_normalize_version_number(FOB_REQUESTED_VERSION 3)
set(VERSION_GIT_TAG v${FOB_REQUESTED_VERSION})

fob_setup_extproj_dirs(Perl ${FOB_REQUESTED_VERSION})

function(_fob_perl_patch_makefile_msvc MAKEFILE_PATH)
    file(COPY_FILE ${MAKEFILE_PATH} ${MAKEFILE_PATH}.bk) 
    file(READ ${MAKEFILE_PATH} MAKEFILE_CONTENTS)

    set(PERL_MSVCVER "MSVC${MSVC_TOOLSET_VERSION}")
    string(REGEX REPLACE "#(CCTYPE\\s*=\\s*${PERL_MSVCVER})"
       "\\1" MAKEFILE_CONTENTS "${MAKEFILE_CONTENTS}")

    cmake_path(GET INSTALL_DIR ROOT_NAME INST_DRV)
    string(REGEX REPLACE "INST_DRV\\s*=\\s*([A-Za-z]:)"
       "\\1" MAKEFILE_CONTENTS "${MAKEFILE_CONTENTS}")

    cmake_path(GET INSTALL_DIR RELATIVE_PART PERL_INST_TOP)
    cmake_path(NATIVE_PATH PERL_INST_TOP NORMALIZE PERL_INST_TOP)
    string(REGEX REPLACE "(INST_TOP\\s*=\\s*\\$\\(INST_DRV\\)\\\\)perl"
       "\\1${PERL_INST_TOP}" MAKEFILE_CONTENTS "${MAKEFILE_CONTENTS}")

    file(WRITE ${MAKEFILE_PATH} "${MAKEFILE_CONTENTS}")
endfunction(_fob_perl_patch_makefile_msvc)

if(MSVC)
    fob_find_vcvarsall(VCVARSALL STRING REQUIRED)
    cmake_path(SET MAKE_DIR ${SOURCE_DIR}/win32)
    cmake_path(NATIVE_PATH ${SOURCE_DIR}/win32 NORMALIZE MAKE_DIR_NATIVE)
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/make_run.bat
"SET VSCMD_START_DIR=${MAKE_DIR_NATIVE}
${VCVARSALL}
CD \"${MAKE_DIR_NATIVE}\"
nmake %1"
    )
    _fob_perl_patch_makefile_msvc(${MAKEFILE_PATH})
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
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${MAKE_COMMAND}
    INSTALL_COMMAND ${MAKE_INSTALL_COMMAND}
)

# TODO 1. All specific compatibility checkers must call a macro with a list 
# of all the variables that they check. Also before including the checker 
# script, _does_cfg_dir_match_args will populate a variable with the list
# of all the variables that are being set. The macro called by the checker
# script will set a flag indicating that the macro has been called and that
# all the variables set before the script was included were expected by the
# script. If the flag is not set, _does_cfg_dir_match_args should produce
# a warning and skip the directory.
