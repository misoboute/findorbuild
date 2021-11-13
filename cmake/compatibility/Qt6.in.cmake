# This module is included by FOB to test if the accompanying build of Qt6 
# is compatible with the request made through 
# fob_find_or_build. It is expected to set the variable FOB_IS_COMPATIBLE to 
# true or false.

fob_declare_compatibility_variables(BUILD_SHARED_LIBS WITH_OPENGL)

fob_are_bools_equal(BUILD_SHARED_LIBS_COMPATIBLE
    ${BUILD_SHARED_LIBS} @BUILD_SHARED_LIBS@)

fob_are_bools_equal(WITH_OPENGL_COMPATIBLE ${WITH_OPENGL} @WITH_OPENGL@)

set(WITH_OPENGL_COMPATIBLE ON)
if(WITH_OPENGL AND (NOT @WITH_OPENGL@))
    set(WITH_OPENGL_COMPATIBLE OFF)
endif()

if(BUILD_SHARED_LIBS_COMPATIBLE AND WITH_OPENGL_COMPATIBLE)
    set(FOB_IS_COMPATIBLE ON)
else()
    set(FOB_IS_COMPATIBLE OFF)
endif()
