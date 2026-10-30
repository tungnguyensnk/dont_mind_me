# libgmsspoof build

Patch-only Play Integrity shield for the GMS DroidGuard process. Loaded into
`com.google.android.gms` by `Bridge` (see `../../Bridge.java`, which the module's
zygisk loader runs in the processes listed under `../../packages/`).

## Why

The whole-system `ro.build.version.security_patch` is spoofed forward (see
`../../spoof.sh`) so a banking/tech app accepts the device. Google Play Integrity
STRONG, however, needs DroidGuard to see the **real** patch that the hardware
keybox attestation (Tricky Store) vouches for. This lib inline-hooks the libc
property reader inside the GMS process only, so DroidGuard reads the real patch
(from `/system/build.prop`) while every other app still sees the forward value.

An earlier build used And64InlineHook, which fails silently on modern arm64
(PAC/BTI, kernel 6.x) — the hook never takes, DroidGuard sees the spoofed patch,
STRONG drops. This build uses ShadowHook (same engine as PlayIntegrityFork),
which is reliable there.

## JNI contract (must match Bridge.java)

- `JNI_OnLoad` — cache the real patch read from `/system/build.prop`.
- `Java_Bridge_activateGms` — install the hook + reset `Build.VERSION.SECURITY_PATCH`,
  called from `Bridge.main()` after app specialization.

## Build (Windows, NDK + bundled cmake/ninja)

```sh
NDK=/d/Data/runner/android_sdk/ndk/28.2.13676358
CMK=/d/Data/runner/android_sdk/cmake/3.22.1/bin
"$CMK/cmake.exe" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
  -DCMAKE_MAKE_PROGRAM="$CMK/ninja.exe" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-29 -DANDROID_STL=c++_static \
  -DCMAKE_BUILD_TYPE=Release -S . -B build
"$CMK/cmake.exe" --build build
"$NDK/toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-strip.exe" --strip-all build/libgmsspoof.so
cp build/libgmsspoof.so ../arm64-v8a/libgmsspoof.so
```

ShadowHook (android-inline-hook v2.0.1) is fetched by CMake at configure time.
arm64-v8a only (the module is arm64-only).
