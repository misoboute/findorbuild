# This module is included by the main FindOrBuild module and the package
# retrieval modules. It includes basic utilities that are usable in almost 
# all contexts.

if(FOB_COMMON_UTILS_INCLUDED)
    return()
endif(FOB_COMMON_UTILS_INCLUDED)
set(FOB_COMMON_UTILS_INCLUDED 1)

# Sets a value to a variable (as default) if it is not already set.
function(fob_set_default_var_value VAR_NAME DEFAULT_VAL)
    if(NOT DEFINED ${VAR_NAME})
        set(${VAR_NAME} ${DEFAULT_VAL} PARENT_SCOPE)
    endif()
endfunction(fob_set_default_var_value)

# Save the current defined state and value of a variable so it can be restored
# later using fob_pop_var
function(fob_push_var VAR_NAME)
    if (DEFINED ${VAR_NAME})
        set(_push_${VAR_NAME} ${${VAR_NAME}} PARENT_SCOPE)
    else()
        unset(${VAR_NAME} PARENT_SCOPE)
    endif()
endfunction(fob_push_var)

# Restore the defined state and value of a variable previously saved using
# fob_push_var
function(fob_pop_var VAR_NAME)
    if (DEFINED _push_${VAR_NAME})
        set(${VAR_NAME} ${_push_${VAR_NAME}} PARENT_SCOPE)
    else()
        unset(${VAR_NAME} PARENT_SCOPE)
    endif()
endfunction(fob_pop_var)

# Compares two variables representing boolean values and sets the specified
# output variable to ON if they both represent the same boolean value and
# to OFF otherwise.
function(fob_are_bools_equal OUTVAR BOOL1 BOOL2)
    set(RESULT OFF)
    if((BOOL1 AND BOOL2) OR ((NOT BOOL1) AND (NOT BOOL2)))
        set(RESULT ON)
    endif()
    set(${OUTVAR} ${RESULT} PARENT_SCOPE)
endfunction()
