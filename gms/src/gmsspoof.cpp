// libgmsspoof: patch-only Play Integrity shield for the GMS DroidGuard process.
//
// drop-in replacement for the old And64InlineHook-based lib (which fails silently on
// arm64 PAC/BTI kernels, letting DroidGuard read the forward-spoofed patch). this build
// uses ShadowHook (bytedance android-inline-hook) which is robust on modern arm64.
//
// keeps the same JNI contract the Bridge expects:
//   JNI_OnLoad            -> cache the REAL security patch read from /system/build.prop
//   Java_Bridge_activateGms -> install the property hook + reset Build.VERSION (post-specialize)
//
// the global property is spoofed forward for banking/tech apps; this makes only the GMS
// process read the REAL patch so Play Integrity STRONG holds (attestation must match it).

#include <android/log.h>
#include <sys/system_properties.h>
#include <jni.h>
#include <dlfcn.h>
#include <string>
#include <map>
#include <fstream>

#include "shadowhook.h"

#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, "PIF/Native", __VA_ARGS__)

static std::string realPatch;

typedef void (*T_Callback)(void *, const char *, const char *, uint32_t);
static std::map<void *, T_Callback> callbacks;

// swap any "*.security_patch" property (ro.build.version.security_patch,
// ro.vendor.build.security_patch, ...) back to the real firmware value
static void modify_callback(void *cookie, const char *name, const char *value, uint32_t serial) {
    if (cookie == nullptr || name == nullptr || value == nullptr || !callbacks.contains(cookie)) return;

    const char *oldValue = value;
    std::string prop(name);
    if (!realPatch.empty() && prop.ends_with(".security_patch")) {
        value = realPatch.c_str();
    }

    if (oldValue != value) LOGD("[%s]: %s -> %s", name, oldValue, value);

    return callbacks[cookie](cookie, name, value, serial);
}

static void (*o_system_property_read_callback)(const prop_info *, T_Callback, void *);

static void my_system_property_read_callback(const prop_info *pi, T_Callback callback, void *cookie) {
    if (pi == nullptr || callback == nullptr || cookie == nullptr) {
        return o_system_property_read_callback(pi, callback, cookie);
    }
    callbacks[cookie] = callback;
    return o_system_property_read_callback(pi, modify_callback, cookie);
}

// ShadowHook calls sh_linker_init for deferred by-name hooks; we hook an already-loaded
// libc symbol by address, so stub it out (same trick PlayIntegrityFork uses).
extern "C" int sh_linker_init(void) { return 0; }

static void doHook() {
    shadowhook_init(SHADOWHOOK_MODE_UNIQUE, false);

    void *sym_addr = dlsym(RTLD_DEFAULT, "__system_property_read_callback");
    if (sym_addr == nullptr) {
        LOGD("Couldn't find '__system_property_read_callback' via dlsym");
        return;
    }

    void *handle = shadowhook_hook_sym_addr(
            sym_addr,
            reinterpret_cast<void *>(my_system_property_read_callback),
            reinterpret_cast<void **>(&o_system_property_read_callback)
    );

    if (handle == nullptr) {
        LOGD("Couldn't hook '__system_property_read_callback'. Error: %d", shadowhook_get_errno());
        return;
    }
    LOGD("Hooked '__system_property_read_callback' at %p (patch=%s)", handle, realPatch.c_str());
}

static std::string readRealPatch() {
    const char *paths[] = {"/system/build.prop", "/system/system/build.prop"};
    const std::string key = "ro.build.version.security_patch=";
    for (const char *p : paths) {
        std::ifstream f(p);
        if (!f) continue;
        std::string line;
        while (std::getline(f, line)) {
            if (line.rfind(key, 0) == 0) {
                std::string v = line.substr(key.size());
                while (!v.empty() && (v.back() == '\r' || v.back() == '\n' || v.back() == ' ' || v.back() == '\t'))
                    v.pop_back();
                return v;
            }
        }
    }
    return "";
}

static void resetBuildVersion(JNIEnv *env) {
    if (realPatch.empty() || env == nullptr) return;
    jclass vcls = env->FindClass("android/os/Build$VERSION");
    if (vcls == nullptr) { env->ExceptionClear(); return; }
    jfieldID fid = env->GetStaticFieldID(vcls, "SECURITY_PATCH", "Ljava/lang/String;");
    if (fid == nullptr) { env->ExceptionClear(); return; }
    jstring val = env->NewStringUTF(realPatch.c_str());
    env->SetStaticObjectField(vcls, fid, val);
    LOGD("Build.VERSION.SECURITY_PATCH reset to %s", realPatch.c_str());
}

extern "C" JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *) {
    realPatch = readRealPatch();
    LOGD("gmsspoof loaded, real security patch = '%s'", realPatch.c_str());
    return JNI_VERSION_1_6;
}

// called by Bridge.main() after app specialization (correct time to install the hook)
extern "C" JNIEXPORT void JNICALL Java_Bridge_activateGms(JNIEnv *env, jclass) {
    if (realPatch.empty()) realPatch = readRealPatch();
    if (realPatch.empty()) {
        LOGD("no real patch found; skipping gms spoof");
        return;
    }
    doHook();
    resetBuildVersion(env);
}
