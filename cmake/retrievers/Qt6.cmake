# NOTE: Qt configure script stores system configuration state in cache variables
# so it won't have to compute them on every run. If the configure/build fails
# and you change some system configuration (install libraries, etc) to fix
# the issue and the configure/build still fails, it might be better to delete
# the current build directory (${BINARY_DIR} set by fob_setup_extproj_dirs)
# and try again. This is especially the case for missing features.

if(FOB_RETRIEVE_QT6_INCLUDED)
    return()
endif(FOB_RETRIEVE_QT6_INCLUDED)
set(FOB_RETRIEVE_QT6_INCLUDED 1)

fob_set_default_var_value(FOB_REQUESTED_VERSION 6.2.1)
fob_set_default_var_value(BUILD_SHARED_LIBS ON)
fob_set_default_var_value(WITH_OPENGL ON)

fob_normalize_version_number(FOB_REQUESTED_VERSION 3)
set(VERSION_GIT_TAG v${FOB_REQUESTED_VERSION})

fob_setup_extproj_dirs(Qt6 ${FOB_REQUESTED_VERSION} BUILD_SHARED_LIBS)

fob_write_specific_compatibility_file(${CONFIG_ROOT_DIR} Qt6)

set(CONFIGURE_OPTIONS -prefix <INSTALL_DIR>)

if(BUILD_SHARED_LIBS)
    list(APPEND CONFIGURE_OPTIONS -shared)
else()
    list(APPEND CONFIGURE_OPTIONS -static)
endif()

if(WITH_OPENGL)
    find_package(OpenGL)
    if(NOT OPENGL_FOUND)
        message(FATAL_ERROR "To build Qt6 with OpenGL support install the \
respective headers for your platform. To disable OpenGL support, set \
WITH_OPENGL config arg to OFF.")
    endif()
else()
    list(APPEND CONFIGURE_OPTIONS -shared)
endif()

if(GENERATOR_IS_MULTI_CONFIG)
    list(APPEND CONFIGURE_OPTIONS -debug-and-release)
else()
    string(TOUPPER "${CMAKE_BUILD_TYPE}" UC_BUILD_TYPE)
    if(UC_BUILD_TYPE STREQUAL RELEASE)
        list(APPEND CONFIGURE_OPTIONS -release)
    elseif(UC_BUILD_TYPE STREQUAL DEBUG)
        list(APPEND CONFIGURE_OPTIONS -debug -optimize-debug)
    elseif(UC_BUILD_TYPE STREQUAL MINSIZEREL)
        list(APPEND CONFIGURE_OPTIONS -release -optimize-size)
    elseif(UC_BUILD_TYPE STREQUAL RELWITHDEBINFO)
        list(APPEND CONFIGURE_OPTIONS -release -force-debug-info)
    endif()
endif()

ExternalProject_Add(
    FOB_Qt6
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
        "-DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}"
)

fob_find_or_build(Perl REQUIRED)

ExternalProject_Add_Step(
    FOB_Qt6 init_repository
    COMMENT "Init/update submodules using init-repository"
    COMMAND ${PERL_EXECUTABLE} ./init-repository -f
    WORKING_DIRECTORY <SOURCE_DIR>
    DEPENDEES download
    DEPENDERS update
)
