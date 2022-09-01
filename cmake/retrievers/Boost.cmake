if(FOB_RETRIEVE_BOOST_INCLUDED)
    return()
endif(FOB_RETRIEVE_BOOST_INCLUDED)
set(FOB_RETRIEVE_BOOST_INCLUDED 1)

fob_set_default_var_value(FOB_REQUESTED_VERSION 1.77.0)
if(WIN32)
    fob_set_default_var_value(BOOST_VARIANT debug release)
    fob_set_default_var_value(BOOST_LINK static)
    fob_set_default_var_value(BOOST_RUNTIME_LINK static)
else()
    fob_set_default_var_value(BOOST_VARIANT release)
    fob_set_default_var_value(BOOST_LINK static shared)
    fob_set_default_var_value(BOOST_RUNTIME_LINK static)
endif()
fob_set_default_var_value(BOOST_THREADING multi)

fob_normalize_version_number(FOB_REQUESTED_VERSION 3)
set(VERSION_GIT_TAG boost-${FOB_REQUESTED_VERSION})

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(BOOST_ADDRESS_MODEL 64)
else(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(BOOST_ADDRESS_MODEL 32)
endif(CMAKE_SIZEOF_VOID_P EQUAL 8)

fob_setup_extproj_dirs(Boost ${FOB_REQUESTED_VERSION})

fob_write_specific_compatibility_file(${CONFIG_ROOT_DIR} Boost)

set(BOOST_SRC_DIR ${SOURCE_DIR}/Source/boost)
if(WIN32)
    set(BOOST_BOOTSTRAP_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/boost_boostrap.bat)
    fob_run_under_vcdevcommand_env(
        ${BOOST_BOOTSTRAP_COMMAND}
        "bootstrap.bat"
        WORKING_DIR ${BOOST_SRC_DIR}
        VSCMD_START_DIR ${BOOST_SRC_DIR}/boost/tools/build/src/engine
    )
    set(BOOST_B2_COMMAND b2.exe)
elseif(UNIX)
    set(BOOST_BOOTSTRAP_COMMAND ./bootstrap.sh)
    set(BOOST_B2_COMMAND ./b2)
endif(WIN32)

ExternalProject_Add(
    FOB_boost
    GIT_REPOSITORY https://github.com/boostorg/boost
    GIT_TAG ${VERSION_GIT_TAG}
    GIT_SHALLOW true
    GIT_PROGRESS true
    DOWNLOAD_DIR ${DOWNLOAD_DIR}
    SOURCE_DIR ${SOURCE_DIR}
    BINARY_DIR ${BINARY_DIR}
    INSTALL_DIR ${INSTALL_DIR}
    TMP_DIR  ${TEMP_DIR}
    STAMP_DIR  ${STAMP_DIR}
    LOG_DIR  ${LOG_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

ExternalProject_Add_Step(
    FOB_boost bootstrap
    COMMENT "Configuring Boost using bootstrap..."
    WORKING_DIRECTORY <SOURCE_DIR>
    DEPENDEES patch
    DEPENDERS configure
    COMMAND ${BOOST_BOOTSTRAP_COMMAND}
)

# To see what values could be set for the toolset, check either of the documents
# "Getting Started on Windows" or "Getting Started on Unix Variants"
# in Boost documentation.
# https://www.boost.org/doc/libs/1_77_0/more/getting_started/index.html
set(BORLAND_COMPILERS Embarcadero Borland)
set(IBM_COMPILERS XL XLClang VisualAge zOS)
set(INTEL_COMPILERS Intel IntelLLVM)

if(MSVC)
    if(MSVC_TOOLSET_VERSION STREQUAL 143)
        set(BOOST_BUILD_TOOLSET msvc-14.3)
    elseif(MSVC_TOOLSET_VERSION STREQUAL 142)
        set(BOOST_BUILD_TOOLSET msvc-14.2)
    elseif(MSVC_TOOLSET_VERSION STREQUAL 141)
        set(BOOST_BUILD_TOOLSET msvc-14.1)
    elseif(MSVC_TOOLSET_VERSION STREQUAL 140)
        set(BOOST_BUILD_TOOLSET msvc-14.0)
    elseif(MSVC_TOOLSET_VERSION STREQUAL 120)
        set(BOOST_BUILD_TOOLSET msvc-12.0)
    elseif(MSVC_TOOLSET_VERSION STREQUAL 110)
        set(BOOST_BUILD_TOOLSET msvc-11.0)
    elseif(MSVC_TOOLSET_VERSION STREQUAL 100)
        set(BOOST_BUILD_TOOLSET msvc-10.0)
    elseif(MSVC_TOOLSET_VERSION STREQUAL 90)
        set(BOOST_BUILD_TOOLSET msvc-9.0)
    else()
        set(BOOST_BUILD_TOOLSET msvc)
    endif()
elseif(APPLE)
    set(BOOST_BUILD_TOOLSET darwin)
elseif(CMAKE_C_COMPILER_ID STREQUAL Clang)
    set(BOOST_BUILD_TOOLSET clang)
elseif(CMAKE_C_COMPILER_ID STREQUAL GNU)
    set(BOOST_BUILD_TOOLSET gcc)
elseif(CMAKE_C_COMPILER_ID IN_LIST BORLAND_COMPILERS)
    set(BOOST_BUILD_TOOLSET borland)
elseif(CMAKE_C_COMPILER_ID STREQUAL HP)
    set(BOOST_BUILD_TOOLSET acc)
elseif(CMAKE_C_COMPILER_ID IN_LIST INTEL_COMPILERS)
    set(BOOST_BUILD_TOOLSET intel)
elseif(CMAKE_C_COMPILER_ID STREQUAL SunPro)
    set(BOOST_BUILD_TOOLSET sun)
elseif(CMAKE_C_COMPILER_ID IN_LIST IBM_COMPILERS)
    set(BOOST_BUILD_TOOLSET vacpp)
endif()

# Complete command line options: b2.exe --help-options
# http://www.boost.org/build/doc/html/bbv2/overview/invocation.html
set (BOOST_BUILD_COMMAND_OPTIONS
    -d1 # We won't need a lot debug output from the build
    -sBOOST_ROOT=<SOURCE_DIR>
# Other layouts place the include directory inside a version suffixed directory
# which can't be found by find_package. Since we already use a separate 
# build/install for each version we don't need 'versioned'. 'system' 
# installs directly into system directories. 'tagged' layout distinguishes
# different variants that are built according to the `build-type`.
    --layout=tagged
    --build-dir=<BINARY_DIR>
    --prefix=<INSTALL_DIR>
    variant=$<JOIN:${BOOST_VARIANT},,>
    link=$<JOIN:${BOOST_LINK},,>
    threading=$<JOIN:${BOOST_THREADING},,>
    runtime-link=$<JOIN:${BOOST_RUNTIME_LINK},,>
    toolset=${BOOST_BUILD_TOOLSET}
    address-model=${BOOST_ADDRESS_MODEL}   # 32/64
)

ExternalProject_Add_Step(
    FOB_boost b2_build
    COMMENT "Building Boost using b2..."
    WORKING_DIRECTORY <SOURCE_DIR>
    DEPENDEES configure
    DEPENDERS build
    COMMAND ${BOOST_B2_COMMAND} -j8 ${BOOST_BUILD_COMMAND_OPTIONS}
)

ExternalProject_Add_Step(
    FOB_boost b2_install
    COMMENT "Installing Boost using b2..."
    WORKING_DIRECTORY <SOURCE_DIR>
    DEPENDEES b2_build
    DEPENDERS install
    COMMAND ${BOOST_B2_COMMAND} ${BOOST_BUILD_COMMAND_OPTIONS} install
)
