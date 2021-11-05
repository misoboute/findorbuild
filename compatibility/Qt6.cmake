# This module is included by FOB to test if the accompanying build of Qt6 
# is compatible with the request made through 
# fob_find_or_build. It is expected to set the variable FOB_IS_COMPATIBLE to 
# true or false.

if(BUILD_SHARED_LIBS EQUAL @BUILD_SHARED_LIBS@)
    set(FOB_IS_COMPATIBLE true)
else()
    set(FOB_IS_COMPATIBLE false)
endif()
