cmake_minimum_required(VERSION 3.13)

set(FOBTEST_ROOT ${CMAKE_CURRENT_LIST_DIR})

list(APPEND CMAKE_MODULE_PATH ${FOBTEST_ROOT})

include(FOBBootstrap)

# fob_find_or_build(GTest 1.10 REQUIRED)
fob_find_or_build(Boost)
