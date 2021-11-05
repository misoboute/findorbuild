# This module is included by FOB to test if the accompanying build of Boost 
# is compatible with the request made through 
# fob_find_or_build. It is expected to set the variable FOB_IS_COMPATIBLE to 
# true or false.

# Presume compatibility at the beginning
set(FOB_IS_COMPATIBLE true)

set(AVAILABLE_VARIANTS @BOOST_VARIANT@)
foreach(VAR ${BOOST_VARIANT})
    if(NOT VAR IN_LIST AVAILABLE_VARIANTS)
        set(FOB_IS_COMPATIBLE false)
        return()
    endif()
endforeach(VAR)

set(AVAILABLE_LINKS @BOOST_LINK@)
foreach(LINK ${BOOST_LINK})
    if(NOT LINK IN_LIST AVAILABLE_LINKS)
        set(FOB_IS_COMPATIBLE false)
        return()
    endif()
endforeach(LINK)

set(AVAILABLE_THREADINGS @BOOST_THREADING@)
foreach(THREADING ${BOOST_THREADING})
    if(NOT LINK IN_LIST AVAILABLE_THREADINGS)
        set(FOB_IS_COMPATIBLE false)
        return()
    endif()
endforeach(THREADING)

set(AVAILABLE_RUNTIME_LINKS @BOOST_RUNTIME_LINK@)
foreach(RTLINK ${BOOST_RUNTIME_LINK})
    if(NOT RTLINK IN_LIST AVAILABLE_RUNTIME_LINKS)
        set(FOB_IS_COMPATIBLE false)
        return()
    endif()
endforeach(RTLINK)
