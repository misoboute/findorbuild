if(FOB_RETRIEVE_GMOCK_INCLUDED)
    return()
endif(FOB_RETRIEVE_GMOCK_INCLUDED)
set(FOB_RETRIEVE_GMOCK_INCLUDED 1)

set(GTEST_VERSIONS 
    "1.0.0" "1.0.1" "1.1.0" "1.2.0" "1.2.1" "1.3.0" "1.4.0" "1.5.0"
    "1.6.0" "1.7.0" "1.8.0" "1.8.1" "1.10.0" "1.11.0" 
)

fob_set_default_var_value(FOB_REQUESTED_VERSION 1.11.0)
fob_set_default_var_value(BUILD_SHARED_LIBS OFF)
fob_set_default_var_value(gtest_force_shared_crt OFF)

fob_normalize_version_number(FOB_REQUESTED_VERSION)
string(REGEX REPLACE "\\.[0-9]$" "" 
    FOB_REQUESTED_VERSION ${FOB_REQUESTED_VERSION})

if(FOB_REQUESTED_VERSION IN_LIST GTEST_VERSIONS)
    set(VERSION_GIT_TAG release-${FOB_REQUESTED_VERSION})
else()
    set(VERSION_GIT_TAG release-1.11.0)
endif()

fob_add_ext_cmake_project(
    GMock ${FOB_REQUESTED_VERSION}
    GIT_REPOSITORY https://github.com/google/googletest
    GIT_TAG ${VERSION_GIT_TAG}
    GIT_SHALLOW true
    GIT_PROGRESS true
    BUILD_DISTINGUISHING_VARS 
        BUILD_SHARED_LIBS
        gtest_force_shared_crt
    CMAKE_CACHE_ARGS
        -DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
        -DBUILD_EXAMPLES:BOOL=OFF
        -DBUILD_TESTING:BOOL=OFF
        -Dgtest_force_shared_crt:BOOL=${gtest_force_shared_crt}
)
