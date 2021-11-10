if(FOB_RETRIEVE_GTEST_INCLUDED)
    return()
endif(FOB_RETRIEVE_GTEST_INCLUDED)
set(FOB_RETRIEVE_GTEST_INCLUDED 1)

fob_set_default_var_value(FOB_REQUESTED_VERSION 1.11.0)
fob_set_default_var_value(BUILD_SHARED_LIBS OFF)
fob_set_default_var_value(gtest_force_shared_crt OFF)

fob_normalize_version_number(FOB_REQUESTED_VERSION 3)
set(VERSION_GIT_TAG release-${FOB_REQUESTED_VERSION})

fob_add_ext_cmake_project(
    GTest ${FOB_REQUESTED_VERSION}
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
