# This module is included by FOB to test if the accompanying build of Boost 
# is compatible with the request made through 
# fob_find_or_build. It is expected to set the variable FOB_IS_COMPATIBLE to 
# true or false.

# Presume compatibility at the beginning
set(FOB_IS_COMPATIBLE true)

foreach(VAR ${BOOST_VARIANT})
    if(NOT VAR IN_LIST "@BOOST_VARIANT@")
        set(FOB_IS_COMPATIBLE false)
        return()
    endif()
endforeach(VAR)

foreach(LINK ${BOOST_LINK})
    if(NOT LINK IN_LIST "@BOOST_LINK@")
        set(FOB_IS_COMPATIBLE false)
        return()
    endif()
endforeach(LINK)

foreach(THREADING ${BOOST_THREADING})
    if(NOT LINK IN_LIST "@BOOST_THREADING@")
        set(FOB_IS_COMPATIBLE false)
        return()
    endif()
endforeach(THREADING)

foreach(RTLINK ${BOOST_RUNTIME_LINK})
    if(NOT RTLINK IN_LIST "@BOOST_RUNTIME_LINK@")
        set(FOB_IS_COMPATIBLE false)
        return()
    endif()
endforeach(RTLINK)
