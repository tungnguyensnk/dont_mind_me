import android.util.Log;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

// the bundled loader calls premain()/main() on the module.prop entrypoint.
// hma runs in system_server only; gms loads its property hook while the module dir is still open.
public final class Bridge {
    private static final String TAG = "DontMindMe";
    private static final String HMA = "org.frknkrc44.hma_oss.zygote.ZygoteEntry";
    private static ClassLoader hma;

    private static native void activateGms();

    public static void premain() {
        hma = Bridge.class.getClassLoader();
        if (isGms()) {
            // hma would cast a BinderProxy to IPackageManager and crash gms, so skip it here;
            // load the library now, then activate its hooks after specialization
            try { loadGms(); } catch (Throwable e) { Log.e(TAG, "gms spoof failed", e); }
        } else {
            call(hma, HMA, "premain");
        }
    }

    public static void main() {
        if (isGms()) {
            try { activateGms(); } catch (Throwable e) { Log.e(TAG, "gms activation failed", e); }
        } else {
            call(hma, HMA, "main");
        }
    }

    private static void loadGms() throws Throwable {
        String dir = (String) getStatic(entry(), "b");
        Log.i(TAG, "gms module dir=" + dir);
        if (dir == null) return;
        // JNI_OnLoad reads the real patch, hooks the libc property readers and resets Build.VERSION
        System.load(dir + "/gms/arm64-v8a/libgmsspoof.so");
        Log.i(TAG, "gms patch spoof loaded");
    }

    // packageName is the obfuscated EntryPoint field "a", set natively before premain
    private static boolean isGms() {
        try {
            String p = (String) getStatic(entry(), "a");
            return p != null && p.startsWith("com.google.android.gms");
        } catch (Throwable e) { return false; }
    }

    private static Class<?> entry() throws Throwable {
        return Class.forName("com.v7878.zygisk.EntryPoint", true, hma);
    }

    private static Object getStatic(Class<?> cls, String name) throws Throwable {
        Field f = cls.getDeclaredField(name);
        f.setAccessible(true);
        return f.get(null);
    }

    private static void call(ClassLoader loader, String name, String phase) {
        try {
            Class<?> cls = Class.forName(name, true, loader);
            Method method = cls.getMethod(phase);
            method.invoke(null);
        } catch (Throwable e) {
            Log.e(TAG, name + "." + phase + " failed", e);
        }
    }
}
