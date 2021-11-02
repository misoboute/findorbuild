# This module is included by FOB to test if the accompanying build of a module 
# is, in generic terms, compatible with the request made through 
# fob_find_or_build. It is expected to set the variable FOB_IS_COMPATIBLE to 
# true or false.

# Presume compatibility at the beginning
set(FOB_IS_COMPATIBLE true)

# bit length compatibility
if(NOT CMAKE_SIZEOF_VOID_P EQUAL @CMAKE_SIZEOF_VOID_P@)
    set(FOB_IS_COMPATIBLE false)
    return()
endif()

# C compiler binary compatibility test - TODO (CMAKE_C_COMPILER_ID)

# C++ compiler binary compatibility test - TODO (CMAKE_CXX_COMPILER_ID)

# Host system test - TODO (CMAKE_SYSTEM_NAME)

# Test CMAKE_OSX_DEPLOYMENT_TARGET compatibility for apple

if(XCODE)
    if(NOT XCODE_VERSION VERSION_EQUAL @XCODE_VERSION@ OR
        NOT CMAKE_OSX_DEPLOYMENT_TARGET VERSION_EQUAL @CMAKE_OSX_DEPLOYMENT_TARGET@)
        set(FOB_IS_COMPATIBLE false)
        return()
    endif()
elseif(MSVC)
    list(APPEND BUILD_DISTINGUISHING_VARS MSVC_TOOLSET_VERSION)
    if(NOT MSVC_TOOLSET_VERSION VERSION_EQUAL @MSVC_TOOLSET_VERSION@)
        set(FOB_IS_COMPATIBLE false)
        return()
    endif()
endif()
