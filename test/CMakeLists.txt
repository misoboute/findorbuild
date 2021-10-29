cmake_minimum_required(VERSION 3.20)

project(FindOrBuildTest)

set(FOBTEST_ROOT ${CMAKE_CURRENT_LIST_DIR})

cmake_path(SET FOBTEST_MODULE_PATH ${FOBTEST_ROOT}/../cmake)
cmake_path(NORMAL_PATH FOBTEST_MODULE_PATH)

list(APPEND CMAKE_MODULE_PATH ${FOBTEST_MODULE_PATH})

message("CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}")

include(FOBBootstrap)

# fob_find_or_build(GTest 1.10 REQUIRED)
fob_find_or_build(Boost)
