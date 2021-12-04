if(FOB_RETRIEVE_OPENSSL_INCLUDED)
    return()
endif(FOB_RETRIEVE_OPENSSL_INCLUDED)
set(FOB_RETRIEVE_OPENSSL_INCLUDED 1)

fob_set_default_var_value(FOB_REQUESTED_VERSION 3.0.0)

fob_normalize_version_number(FOB_REQUESTED_VERSION 3)
set(VERSION_GIT_TAG openssl-${FOB_REQUESTED_VERSION})

fob_add_ext_cmake_project(
    Poco ${FOB_REQUESTED_VERSION}
    GIT_REPOSITORY https://github.com/openssl/openssl.git
    GIT_TAG ${VERSION_GIT_TAG}
    GIT_SHALLOW true
    GIT_PROGRESS true
    CMAKE_CACHE_ARGS
        -DBUILD_EXAMPLES:BOOL=OFF
        -DBUILD_TESTING:BOOL=OFF
)
