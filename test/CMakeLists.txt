cmake_minimum_required(VERSION 3.18)

project(FindOrBuildTest)

set(FOBTEST_ROOT ${CMAKE_CURRENT_LIST_DIR})

cmake_path(SET FOBTEST_MODULE_PATH ${FOBTEST_ROOT}/../cmake)
cmake_path(NORMAL_PATH FOBTEST_MODULE_PATH)

list(APPEND CMAKE_MODULE_PATH ${FOBTEST_MODULE_PATH})

include(FOBBootstrap)

fob_find_or_build(GTest 1.10 REQUIRED
    CFG_ARGS
        -DBUILD_SHARED_LIBS=OFF
        -Dgtest_force_shared_crt=OFF
)
# if(NOT GTest_FOUND)
#     message(FATAL_ERROR "GTest NOT FOUND")
# endif()
# fob_find_or_build(Boost REQUIRED)
# if(NOT Boost_FOUND)
#     message(FATAL_ERROR "Boost NOT FOUND")
# endif()

fob_find_or_build(Qt6 REQUIRED)
