if(FOB_COMMON_UTILS_INCLUDED)
    return()
endif(FOB_COMMON_UTILS_INCLUDED)
set(FOB_COMMON_UTILS_INCLUDED 1)

function(fob_set_default_var_value VAR_NAME DEFAULT_VAL)
    if(NOT DEFINED ${VAR_NAME})
        set(${VAR_NAME} ${DEFAULT_VAL} PARENT_SCOPE)
    endif()
endfunction(fob_set_default_var_value)

function(fob_push_var VAR_NAME)
    if (DEFINED ${VAR_NAME})
        set(_push_${VAR_NAME} ${${VAR_NAME}} PARENT_SCOPE)
    else()
        unset(${VAR_NAME} PARENT_SCOPE)
    endif()
endfunction(fob_push_var)

function(fob_pop_var VAR_NAME)
    if (DEFINED _push_${VAR_NAME})
        set(${VAR_NAME} ${_push_${VAR_NAME}} PARENT_SCOPE)
    else()
        unset(${VAR_NAME} PARENT_SCOPE)
    endif()
endfunction(fob_pop_var)