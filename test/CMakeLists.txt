cmake_minimum_required(VERSION 3.18)

project(FindOrBuildTest)

set(FOBTEST_ROOT ${CMAKE_CURRENT_LIST_DIR})

cmake_path(SET FOBTEST_MODULE_PATH ${FOBTEST_ROOT}/../cmake)
cmake_path(NORMAL_PATH FOBTEST_MODULE_PATH)

list(APPEND CMAKE_MODULE_PATH ${FOBTEST_MODULE_PATH})

include(FOBBootstrap)

fob_find_or_build(GTest 1.11 REQUIRED
    CFG_ARGS
        -DBUILD_SHARED_LIBS=OFF
        -Dgtest_force_shared_crt=OFF
)

fob_find_or_build(Boost 1.77 REQUIRED)

fob_find_or_build(Perl REQUIRED USE_SYSTEM_PACKAGES NEVER)

fob_find_or_build(Qt6 REQUIRED)
