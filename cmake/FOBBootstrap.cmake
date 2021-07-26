# This cmake mini-module bootstraps the necessary components of the FindOrBuild
# module if they have not already been downloaded to the current build
# directory. It will then automatically include the FindOrBuild module if
# the module is downloaded and issues a warning otherwise.

if(FOB_BOOTSTRAP_INCLUDED)
    return()
endif(FOB_BOOTSTRAP_INCLUDED)
set(FOB_BOOTSTRAP_INCLUDED 1)

cmake_minimum_required(VERSION 3.14)

set(FOB_MODULE_DIR_URL https://raw.githubusercontent.com/misoboute/findorbuild/main/cmake)
set(FOB_MODULE_DIR ${CMAKE_BINARY_DIR}/fob/cmake)

# Downloads a file from the specified URL if it doesn't already exist at the
# specified local path or if the hash of the existing local file is different 
# from the expected hash. On download failure, it issues an author warning.

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

_download_fob_module_if_not_exists(CommonUtils) 
_download_fob_module_if_not_exists(FindOrBuild) 
_download_fob_module_if_not_exists(PackageUtils) 

if(EXISTS ${FOB_MODULE_DIR}/FindOrBuild.cmake)
    include(${FOB_MODULE_DIR}/FindOrBuild.cmake)
endif()
