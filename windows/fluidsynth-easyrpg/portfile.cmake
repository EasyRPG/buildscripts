vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO FluidSynth/fluidsynth
    REF fc21d284dc7fcacdbc456f30228110a55e6e79f6 #v2.2.2
    SHA512 33fa90d238686952d0a163ac63f1a6a61b293998c84f9c6e7ea72750c92e5f1e6b35cd3354117f4a2b2bd283117e97f3c729738d353eddbd076c5290c2080c4d
    HEAD_REF master
    PATCHES
       force-x86-gentables.patch
       fluidsynth-no-glib.patch
)

set(feature_list dbus jack libinstpatch libsndfile midishare opensles oboe oss sdl2 pulseaudio readline lash alsa systemd coreaudio coremidi dart)
set(FEATURE_OPTIONS)
foreach(_feature IN LISTS feature_list)
    list(APPEND FEATURE_OPTIONS -Denable-${_feature}:BOOL=OFF)
endforeach()

#vcpkg_find_acquire_program(PKGCONFIG)
vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS 
        ${FEATURE_OPTIONS}
    OPTIONS_DEBUG
        -Denable-debug:BOOL=ON
)

vcpkg_install_cmake()

# Copy fluidsynth.exe to tools dir
vcpkg_copy_tools(TOOL_NAMES fluidsynth AUTO_CLEAN)

# Remove unnecessary files
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/debug/bin)
endif()

# Handle copyright
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
