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

# Sets of mutually binary-compatible compilers based on OS type
if(APPLE)
    set(BINARY_COMPATIBLE_COMPILERS_1 AppleClang GNU)
    set(BINARY_COMPATIBLE_COMPILERS_2 GHS)
    set(NUM_BINARY_COMPATIBLE_COMPILER_SETS 2)
elseif(WIN32)
    set(BINARY_COMPATIBLE_COMPILERS_1
        Clang GNU Intel IntelLLVM OpenWatcom PathScale PGI)
    set(BINARY_COMPATIBLE_COMPILERS_2 MSVC)
    set(BINARY_COMPATIBLE_COMPILERS_3 Embarcadero Borland)
    set(BINARY_COMPATIBLE_COMPILERS_4 GHS)
    set(BINARY_COMPATIBLE_COMPILERS_5 XL XLClang)
    set(NUM_BINARY_COMPATIBLE_COMPILER_SETS 5)
elseif(UNIX)
    set(BINARY_COMPATIBLE_COMPILERS_1
        Clang GNU Intel IntelLLVM OpenWatcom PathScale PGI)
    set(BINARY_COMPATIBLE_COMPILERS_2 GHS)
    set(BINARY_COMPATIBLE_COMPILERS_3 XL XLClang)
    set(BINARY_COMPATIBLE_COMPILERS_4 SunPro)
    set(NUM_BINARY_COMPATIBLE_COMPILER_SETS 4)
endif()

# Add singular sets that could (might?) be used with all OS types
foreach(COMPILER_SET Bruce "Fujitsu;FujitsuClang" HP IAR SDCC TinyCC)
    math(EXPR NUM_BINARY_COMPATIBLE_COMPILER_SETS 
        "NUM_BINARY_COMPATIBLE_COMPILER_SETS + 1")
    set(BINARY_COMPATIBLE_COMPILERS_${NUM_BINARY_COMPATIBLE_COMPILER_SETS}
        ${COMPILER_SET})
endforeach(COMPILER_SET)

# C compiler binary compatibility test
foreach(CNT RANGE 1 ${NUM_BINARY_COMPATIBLE_COMPILER_SETS})
    set(COMPATIBLE_SET ${BINARY_COMPATIBLE_COMPILERS_${CNT}})
    if(CMAKE_C_COMPILER_ID IN_LIST COMPATIBLE_SET)
        if(NOT @CMAKE_C_COMPILER_ID@ IN_LIST BINARY_COMPATIBLE_COMPILERS)
            set(FOB_IS_COMPATIBLE false)
            return()
        endif()
        break()
    endif()
endforeach(CNT)

# C++ compiler binary compatibility test
foreach(CNT RANGE 1 ${NUM_BINARY_COMPATIBLE_COMPILER_SETS})
    set(COMPATIBLE_SET ${BINARY_COMPATIBLE_COMPILERS_${CNT}})
    if(CMAKE_CXX_COMPILER_ID IN_LIST COMPATIBLE_SET)
        if(NOT @CMAKE_CXX_COMPILER_ID@ IN_LIST BINARY_COMPATIBLE_COMPILERS)
            set(FOB_IS_COMPATIBLE false)
            return()
        endif()
        break()
    endif()
endforeach(CNT)

# Test target OS compatibility
if(NOT CMAKE_SYSTEM_NAME STREQUAL @CMAKE_SYSTEM_NAME@)
    set(FOB_IS_COMPATIBLE false)
    return()
endif()

if(XCODE)
    # Test CMAKE_OSX_DEPLOYMENT_TARGET compatibility
    if(NOT XCODE_VERSION VERSION_EQUAL @XCODE_VERSION@ OR
        NOT CMAKE_OSX_DEPLOYMENT_TARGET VERSION_EQUAL @CMAKE_OSX_DEPLOYMENT_TARGET@)
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
