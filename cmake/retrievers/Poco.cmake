if(FOB_RETRIEVE_POCO_INCLUDED)
    return()
endif(FOB_RETRIEVE_POCO_INCLUDED)
set(FOB_RETRIEVE_POCO_INCLUDED 1)

fob_set_default_var_value(FOB_REQUESTED_VERSION 1.11.0)
fob_set_default_var_value(BUILD_SHARED_LIBS OFF)

fob_normalize_version_number(FOB_REQUESTED_VERSION 3)
set(VERSION_GIT_TAG poco-${FOB_REQUESTED_VERSION}-release)

fob_add_ext_cmake_project(
    Poco ${FOB_REQUESTED_VERSION}
    GIT_REPOSITORY https://github.com/pocoproject/poco.git
    GIT_TAG ${VERSION_GIT_TAG}
    GIT_SHALLOW true
    GIT_PROGRESS true
    BUILD_DISTINGUISHING_VARS 
        BUILD_SHARED_LIBS
    CMAKE_CACHE_ARGS
        -DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
        -DBUILD_EXAMPLES:BOOL=OFF
        -DBUILD_TESTING:BOOL=OFF
)
