cmake_minimum_required(VERSION 3.22.1)
project(gmsspoof)
enable_language(C CXX ASM)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ShadowHook (bytedance android-inline-hook) built statically into libgmsspoof.so.
# robust arm64 inline hooking (PAC/BTI/kernel 6.x safe) where the old And64InlineHook
# build failed silently. the sh_linker_init patch mirrors PlayIntegrityFork: we hook an
# already-loaded libc symbol by address, so the linker-monitor init is stubbed out.
include(FetchContent)
FetchContent_Declare(
  shadowhook
  GIT_REPOSITORY https://github.com/bytedance/android-inline-hook.git
  GIT_TAG        v2.0.1
  PATCH_COMMAND  perl -pi -e "s/sh_linker_init/sh_linker_init_dummy/g" shadowhook/src/main/cpp/sh_linker.c
)
FetchContent_GetProperties(shadowhook)
if(NOT shadowhook_POPULATED)
  FetchContent_Populate(shadowhook)
endif()

set(SH ${shadowhook_SOURCE_DIR}/shadowhook/src/main/cpp)
file(GLOB SHADOWHOOK_SRC ${SH}/*.c ${SH}/common/*.c ${SH}/third_party/xdl/*.c)
# sh_jni.c exports its own JNI_OnLoad; we provide ours and call the C API directly
list(FILTER SHADOWHOOK_SRC EXCLUDE REGEX "sh_jni\\.c$")
file(GLOB SHADOWHOOK_ARCH_SRC ${SH}/arch/arm64/*.c ${SH}/arch/arm64/*.S)

include_directories(
    ${SH} ${SH}/common ${SH}/include
    ${SH}/third_party/bsd ${SH}/third_party/lss ${SH}/third_party/xdl
    ${SH}/arch/arm64
)

add_library(gmsspoof SHARED gmsspoof.cpp ${SHADOWHOOK_SRC} ${SHADOWHOOK_ARCH_SRC})
target_compile_options(gmsspoof PRIVATE -Wno-unused-parameter -fvisibility=hidden -O2)
target_link_libraries(gmsspoof PRIVATE log)
