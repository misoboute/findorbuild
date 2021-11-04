if(FOB_RETRIEVE_BOOST_INCLUDED)
    return()
endif(FOB_RETRIEVE_BOOST_INCLUDED)
set(FOB_RETRIEVE_BOOST_INCLUDED 1)

set(BOOST_VERSIONS 
    "1.18.0" "1.18.2" "1.18.3" "1.19.0" "1.20.1" "1.20.2" "1.16.1" "1.17.0" 
    "1.18.0" "1.18.2" "1.18.3" "1.19.0" "1.20.1" "1.20.2" "1.21.0" "1.21.1" 
    "1.21.2" "1.22.0" "1.23.0" "1.24.0" "1.25.0" "1.25.1" "1.26.0" "1.27.0" 
    "1.28.0" "1.29.0" "1.30.0" "1.30.1" "1.30.2" "1.31.0" "1.32.0" "1.33.0" 
    "1.33.1" "1.34.0" "1.34.1" "1.35.0" "1.36.0" "1.37.0" "1.38.0" "1.39.0" 
    "1.40.0" "1.41.0" "1.42.0" "1.43.0" "1.44.0" "1.45.0" "1.46.0" "1.46.1" 
    "1.47.0" "1.48.0" "1.49.0" "1.50.0" "1.51.0" "1.52.0" "1.53.0" "1.54.0" 
    "1.55.0" "1.56.0" "1.57.0" "1.58.0" "1.59.0" "1.60.0" "1.61.0" "1.62.0" 
    "1.63.0" "1.64.0" "1.65.0" "1.65.1" "1.66.0" "1.67.0" "1.68.0" "1.69.0" 
    "1.70.0" "1.71.0" "1.72.0" "1.73.0" "1.74.0" "1.75.0" "1.76.0" "1.77.0" 
)

list(GET BOOST_VERSIONS -1 BOOST_LATEST_VERSION)

fob_set_default_var_value(FOB_REQUESTED_VERSION 1.77.0)
if(WIN32)
    fob_set_default_var_value(BOOST_VARIANT debug release)
    fob_set_default_var_value(BOOST_LINK static)
else()
    fob_set_default_var_value(BOOST_VARIANT release)
    fob_set_default_var_value(BOOST_LINK static shared)
endif()
fob_set_default_var_value(BOOST_THREADING multi)
fob_set_default_var_value(BOOST_RUNTIME_LINK ${BOOST_LINK})

fob_normalize_version_number(FOB_REQUESTED_VERSION)
string(REGEX REPLACE "\\.[0-9]$" "" 
    FOB_REQUESTED_VERSION ${FOB_REQUESTED_VERSION})

if(NOT FOB_REQUESTED_VERSION IN_LIST BOOST_VERSIONS AND
    FOB_REQUESTED_VERSION VERSION_LESS BOOST_LATEST_VERSION)
    set(FOB_REQUESTED_VERSION ${BOOST_LATEST_VERSION})
endif()
set(VERSION_GIT_TAG boost-${FOB_REQUESTED_VERSION})

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(BOOST_ADDRESS_MODEL 64)
else(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(BOOST_ADDRESS_MODEL 32)
endif(CMAKE_SIZEOF_VOID_P EQUAL 8)

set(BOOST_SRC_DIR ${SOURCE_DIR}/Source/boost)
if(WIN32)
    # The bootstrap must be run from an MSVS developer command prompt.
    # We shall set the environment instead using vcvarsall in a batch
    # file.
    # VS 2017 vcvarsall changes directory to a different path and the build
    # is messed up. Must CD to the sources directory after vcvarsall.
    # https://stackoverflow.com/questions/46681881/visual-studio-2017-developer-command-prompt-switches-current-directory?rq=1
    fob_find_vcvarsall(VCVARSALL STRING REQUIRED)
    file(TO_NATIVE_PATH ${BOOST_SRC_DIR} BOOST_SRC_DIR_NATIVE)
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/boost_boostrap.bat
"SET VSCMD_START_DIR=${BOOST_SRC_DIR_NATIVE}\\boost\\tools\\build\\src\\engine
${VCVARSALL}
CD \"${BOOST_SRC_DIR_NATIVE}\"
bootstrap.bat"
    )
    set(BOOST_BOOTSTRAP_COMMAND
        ${CMAKE_CURRENT_BINARY_DIR}/boost_boostrap.bat)
    set(BOOST_B2_COMMAND b2.exe)
elseif(UNIX)
    set(BOOST_BOOTSTRAP_COMMAND ./bootstrap.sh)
    set(BOOST_B2_COMMAND ./b2)
endif(WIN32)

fob_setup_extproj_dirs(boost ${FOB_REQUESTED_VERSION})

fob_write_specific_compatibility_file(${CONFIG_ROOT_DIR} Boost)

ExternalProject_Add(
    FOB_boost
    GIT_REPOSITORY https://github.com/boostorg/boost
    GIT_TAG ${VERSION_GIT_TAG}
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

# To see what values could be set for the toolset, search for `<toolset>`
# within the jamfiles throughout the boost source. Other values are: clang, gcc,
# intel-linux, msvc.
if(MSVC)
    if(MSVC_TOOLSET_VERSION STREQUAL 142)
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
elseif(CMAKE_C_COMPILER_ID STREQUAL CLANG)
    set(BOOST_BUILD_TOOLSET clang)
elseif(CMAKE_C_COMPILER_ID STREQUAL GCC)
    set(BOOST_BUILD_TOOLSET gcc)
elseif(CMAKE_C_COMPILER_ID IN_LIST Borland Embarcadero)
    set(BOOST_BUILD_TOOLSET borland)
elseif(CMAKE_C_COMPILER_ID STREQUAL HP)
    set(BOOST_BUILD_TOOLSET acc)
elseif(CMAKE_C_COMPILER_ID IN_LIST Intel IntelLLVM)
    set(BOOST_BUILD_TOOLSET intel)
elseif(CMAKE_C_COMPILER_ID STREQUAL SunPro)
    set(BOOST_BUILD_TOOLSET sun)
elseif(CMAKE_C_COMPILER_ID IN_LIST XL XLClang VisualAge zOS)
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
