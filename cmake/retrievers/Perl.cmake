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

fob_set_default_var_value(FOB_REQUESTED_VERSION 6.2.1)

fob_normalize_version_number(FOB_REQUESTED_VERSION 3)
set(VERSION_GIT_TAG v${FOB_REQUESTED_VERSION})

fob_setup_extproj_dirs(Perl ${FOB_REQUESTED_VERSION}
    BUILD_SHARED_LIBS WITH_OPENGL)

fob_write_specific_compatibility_file(${CONFIG_ROOT_DIR} Perl)


fob_semicolon_escape_list(ESCAPED_CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH})

ExternalProject_Add(
    FOB_Perl
    GIT_REPOSITORY https://code.qt.io/qt/qt5.git
    GIT_TAG ${VERSION_GIT_TAG}
    GIT_SHALLOW true
    GIT_PROGRESS true
    GIT_SUBMODULES ""
    UPDATE_COMMAND ""
    DOWNLOAD_DIR ${DOWNLOAD_DIR}
    SOURCE_DIR ${SOURCE_DIR}
    BINARY_DIR ${BINARY_DIR}
    TMP_DIR ${TEMP_DIR}
    STAMP_DIR ${STAMP_DIR}
    LOG_DIR ${LOG_DIR}
    INSTALL_DIR ${INSTALL_DIR}
    CONFIGURE_COMMAND 
        <SOURCE_DIR>/configure$<$<BOOL:${WIN32}>:.bat> ${CONFIGURE_OPTIONS} --
        -DCMAKE_C_COMPILER:PATH=${CMAKE_C_COMPILER}
        -DCMAKE_CXX_COMPILER:PATH=${CMAKE_CXX_COMPILER}
        -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET}
        "-DCMAKE_PREFIX_PATH:STRING=${ESCAPED_CMAKE_PREFIX_PATH}"
)

# TODO 1. All specific compatibility checkers must call a macro with a list 
# of all the variables that they check. Also before including the checker 
# script, _does_cfg_dir_match_args will populate a variable with the list
# of all the variables that are being set. The macro called by the checker
# script will set a flag indicating that the macro has been called and that
# all the variables set before the script was included were expected by the
# script. If the flag is not set, _does_cfg_dir_match_args should produce
# a warning and skip the directory.
