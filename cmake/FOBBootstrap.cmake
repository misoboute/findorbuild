# This cmake mini-module bootstraps the necessary components of the FindOrBuild
# module if they have not already been downloaded to the current build
# directory. It will then automatically include the FindOrBuild module if
# the module is downloaded and issues a warning otherwise.

if(FOB_BOOTSTRAP_INCLUDED)
    return()
endif(FOB_BOOTSTRAP_INCLUDED)
set(FOB_BOOTSTRAP_INCLUDED 1)

cmake_minimum_required(3.14)

set(FOB_MODULE_DIR_URL https://raw.githubusercontent.com/misoboute/findorbuild/38bf1adaaff90cc81a06ed4b3ee1e07cfca0f225/cmake)
set(FOB_MODULE_DIR ${CMAKE_BINARY_DIR}/fob/cmake)

# Downloads a file from the specified URL if it doesn't already exist at the
# specified local path or if the hash of the existing local file is different 
# from the expected hash. On download failure, it issues an author warning.
function(_fob_download_if_different URL LOCAL_PATH SHA256_HASH)
    set(DOWNLOAD_NEEDED TRUE)
    if(EXISTS ${LOCAL_PATH})
        file(HASH ${LOCAL_PATH} EXISTING_FILE_HASH)
        if (EXISTING_FILE_HASH STREQUAL SHA256_HASH)
            set(DOWNLOAD_NEEDED FALSE)
        endif()
    endif()

    if(DOWNLOAD_NEEDED)
        file(DOWNLOAD ${URL} ${LOCAL_PATH} STATUS DL_STAT
            EXPECTED_HASH SHA256=${SHA256_HASH})

        list(POP_FRONT DL_STAT ERRNO)
        if(ERRNO)
            list(POP_FRONT DL_STAT MSG)
            message(AUTHOR_WARNING
                "Failed to download from ${URL} to ${LOCAL_PATH} => ${MSG}")
        endif()
    endif()
endfunction(_fob_download_if_different)

_fob_download_if_different(
    ${FOB_MODULE_FILE_URL} ${FOB_MODULE_FILE_PATH} ${FOB_MODULE_FILE_HASH})

_fob_download_if_different(
    ${FOB_MODULE_DIR_URL}/CommonUtils.cmake
    ${FOB_MODULE_DIR}/CommonUtils.cmake
) 

_fob_download_if_different(
    ${FOB_MODULE_DIR_URL}/FindUtils.cmake
    ${FOB_MODULE_DIR}/FindUtils.cmake
) 

_fob_download_if_different(
    ${FOB_MODULE_DIR_URL}/FindOrBuild.cmake
    ${FOB_MODULE_DIR}/FindOrBuild.cmake
) 

_fob_download_if_different(
    ${FOB_MODULE_DIR_URL}/PackageUtils.cmake
    ${FOB_MODULE_DIR}/PackageUtils.cmake
) 

if(EXISTS ${FOB_MODULE_DIR_URL}/FindOrBuild.cmake)
    include(${FOB_MODULE_DIR_URL}/FindOrBuild.cmake)
endif()
