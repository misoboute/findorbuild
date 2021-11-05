if(FOB_RETRIEVE_QT6_INCLUDED)
    return()
endif(FOB_RETRIEVE_QT6_INCLUDED)
set(FOB_RETRIEVE_QT6_INCLUDED 1)

set(QT5_VERSIONS 
    "5.1.0" "5.1.1" "5.2.0" "5.2.1" "5.3.0" "5.3.1" "5.3.2" "5.4.0" "5.4.1" 
    "5.4.2" "5.5.0" "5.5.1" "5.6.0" "5.6.1" "5.6.2" "5.6.3" "5.7.0" "5.7.1" 
    "5.8.0" "5.9.0" "5.9.1" "5.9.2" "5.9.3" "5.9.4" "5.9.5" "5.9.6" "5.9.7" 
    "5.9.8" "5.9.9" "5.10.0" "5.10.1" "5.11.0" "5.11.1" "5.11.2" "5.11.3" 
    "5.12.0" "5.12.1" "5.12.10" "5.12.11" "5.12.2" "5.12.3" "5.12.4" 
    "5.12.5" "5.12.6" "5.12.7" "5.12.8" "5.12.9" "5.13.0" "5.13.1" "5.13.2" 
    "5.14.0" "5.14.1" "5.14.2" "5.15.0" "5.15.1" "5.15.2"
)

set(QT6_VERSIONS 
    "6.0.0" "6.0.1" "6.0.2" "6.0.3" "6.0.4" "6.1.0" "6.1.1" "6.1.2" "6.1.3" 
    "6.2.0" "6.2.1"
)

list(GET QT6_VERSIONS -1 QT6_LATEST_VERSION)

fob_set_default_var_value(FOB_REQUESTED_VERSION ${QT6_LATEST_VERSION})
fob_set_default_var_value(BUILD_SHARED_LIBS OFF)

fob_normalize_version_number(FOB_REQUESTED_VERSION 3)
if(NOT FOB_REQUESTED_VERSION IN_LIST GTEST_VERSIONS AND
    FOB_REQUESTED_VERSION VERSION_LESS GTEST_LATEST_VERSION)
    set(FOB_REQUESTED_VERSION ${GTEST_LATEST_VERSION})
endif()
fob_normalize_version_number(FOB_REQUESTED_VERSION 3)
set(VERSION_GIT_TAG v${FOB_REQUESTED_VERSION})

fob_add_ext_cmake_project(
    Qt6 ${FOB_REQUESTED_VERSION}
    GIT_REPOSITORY https://code.qt.io/qt/qt5.git
    GIT_TAG ${VERSION_GIT_TAG}
    GIT_SHALLOW true
    GIT_PROGRESS true
    GIT_SUBMODULES ""
    BUILD_DISTINGUISHING_VARS 
        BUILD_SHARED_LIBS
    CMAKE_CACHE_ARGS
        -DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
        -DBUILD_EXAMPLES:BOOL=OFF
        -DBUILD_TESTING:BOOL=OFF
)

ExternalProject_Add_Step(FOB_Qt6 init_repository
    COMMENT "Init/update submodules using init-repository"
    COMMAND ./init-repository
    WORKING_DIRECTORY <SOURCE_DIR>
    DEPENDEES download
    DEPENDERS update
)