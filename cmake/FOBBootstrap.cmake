# This cmake mini-module bootstraps the necessary components of the FindOrBuild
# module if they have not already been downloaded to the current build
# directory. It will then automatically include the FindOrBuild module if
# the module is downloaded and issues a warning otherwise.

if(FOB_BOOTSTRAP_INCLUDED)
    return()
endif(FOB_BOOTSTRAP_INCLUDED)
set(FOB_BOOTSTRAP_INCLUDED 1)

cmake_minimum_required(VERSION 3.15)

set(FOB_ROOT_DIR_URL 
    https://raw.githubusercontent.com/misoboute/findorbuild/main)
set(FOB_MODULE_DIR_URL ${FOB_ROOT_DIR_URL}/cmake)

set(FOB_BINARY_ROOT_DIR ${CMAKE_BINARY_DIR}/fob)
set(FOB_MODULE_DIR ${FOB_BINARY_ROOT_DIR}/cmake)

# Downloads a FOB module from the upstream repository if it hasn't already 
# been downloaded.
function(_download_fob_module_if_not_exists MOD_NAME)
    set(URL ${FOB_MODULE_DIR_URL}/${MOD_NAME}.cmake)
    set(LOCAL_PATH ${FOB_MODULE_DIR}/${MOD_NAME}.cmake)
    
    if(NOT EXISTS ${LOCAL_PATH})
        file(DOWNLOAD ${URL} ${LOCAL_PATH} STATUS DL_STAT)
        list(POP_FRONT DL_STAT ERRNO)
        if(ERRNO)
            list(POP_FRONT DL_STAT MSG)
            message(AUTHOR_WARNING
                "Failed to download from ${URL} to ${LOCAL_PATH} => ${MSG}")
        endif()
    endif()
endfunction(_download_fob_module_if_not_exists)

_download_fob_module_if_not_exists(FindOrBuild) 
_download_fob_module_if_not_exists(PackageUtils) 

if(EXISTS ${FOB_MODULE_DIR}/FindOrBuild.cmake)
    include(${FOB_MODULE_DIR}/FindOrBuild.cmake)
endif()
