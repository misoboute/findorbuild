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

# C and C++ compiler binary compatibility test
fob_get_binary_compatible_compilers(
    @CMAKE_C_COMPILER_ID@ COMPATIBLE_C_COMPILERS)

fob_get_binary_compatible_compilers(
    @CMAKE_CXX_COMPILER_ID@ COMPATIBLE_CXX_COMPILERS)

if(NOT @CMAKE_C_COMPILER_ID@ IN_LIST COMPATIBLE_C_COMPILERS OR
    NOT @CMAKE_CXX_COMPILER_ID@ IN_LIST COMPATIBLE_CXX_COMPILERS)
    set(FOB_IS_COMPATIBLE false)
    return()
    break()
endif()

# Test target OS compatibility
# TODO - Don't know the clear inter-OS binary compatibility. Assume that
# each OS binary is only usable on the same OS.
if(NOT CMAKE_SYSTEM_NAME STREQUAL @CMAKE_SYSTEM_NAME@)
    set(FOB_IS_COMPATIBLE false)
    return()
endif()

if(XCODE)
    # Test CMAKE_OSX_DEPLOYMENT_TARGET compatibility
    if(NOT XCODE_VERSION VERSION_EQUAL @XCODE_VERSION@ OR
        NOT CMAKE_OSX_DEPLOYMENT_TARGET 
            VERSION_EQUAL @CMAKE_OSX_DEPLOYMENT_TARGET@)
        set(FOB_IS_COMPATIBLE false)
        return()
    endif()
elseif(MSVC)
    # Test MSVC toolset version compatibility
    list(APPEND BUILD_DISTINGUISHING_VARS MSVC_TOOLSET_VERSION)
    if(NOT MSVC_TOOLSET_VERSION VERSION_EQUAL @MSVC_TOOLSET_VERSION@)
        set(FOB_IS_COMPATIBLE false)
        return()
    endif()
endif()
