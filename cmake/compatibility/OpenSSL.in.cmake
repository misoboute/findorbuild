# This module is included by FOB to test if the accompanying build of GTest 
# is compatible with the request made through 
# fob_find_or_build. It is expected to set the variable FOB_IS_COMPATIBLE to 
# true or false.

# If this file exists, it must at least call this even if without arguments
fob_declare_compatibility_variables()   
set(FOB_IS_COMPATIBLE ON)
