SKIPUNZIP=0

# --- logging --------------------------------------------------------------
# step() shows a line in the installer AND records it; die() records then aborts.
# install log lands at $MODPATH/install.log (i.e. the live module dir after reboot).
logi() { :; }; logw() { :; }; loge() { :; }
LOG_TAG=install
LOGFILE="$MODPATH/install.log"
[ -f "$MODPATH/log.sh" ] && . "$MODPATH/log.sh"
step() { ui_print "- $1"; logi "$1"; }
die()  { loge "$1"; abort "! $1"; }
logi "install started (arch=$ARCH api=$API ksu=${KSU:-} apatch=${APATCH:-} ksu_ver=${KSU_VER_CODE:-})"

[ "$ARCH" = arm64 ] || die "arm64 only"
[ "$API" -ge 29 ] || die "Android 10+ required"
{ [ "$KSU" = true ] || [ "$APATCH" = true ]; } || die "KernelSU or APatch required"
[ "$KSU" != true ] || [ "${KSU_VER_CODE:-0}" -ge 10670 ] || die "update KernelSU and KernelSU Manager"
[ "$BOOTMODE" = true ] || die "install from recovery is not supported"

# conflicting modules (nomount, HMA, Tricky Store, PIF, ...) are auto-disabled below,
# not aborted on — their functions are all bundled into this module now

set_perm "$MODPATH/bin/nm" 0 0 0755
set_perm "$MODPATH/bin/lkmloader" 0 0 0755
set_perm "$MODPATH/bin/hbd" 0 0 0755
nm="$MODPATH/bin/nm"
version=$("$nm" version 2>/dev/null)
if [ -z "$version" ] || grep -q '^nomount ' /proc/modules; then
    kmi=$(uname -r | grep -o 'android[0-9][0-9]*' | head -n 1)
    kernel=$(uname -r | cut -d. -f 1,2)
    if [ -n "$kmi" ]; then
        ko="$MODPATH/lkm/nomount-$kmi-$kernel.ko"
    else
        # a uname spoof can strip the androidXX KMI token; KernelSU still reports the
        # real KMI (e.g. "android16-6.12") which matches the bundled driver file name
        ko="$MODPATH/lkm/nomount-$(/data/adb/ksud boot-info current-kmi 2>/dev/null).ko"
    fi
    logi "resolving nomount driver: kmi=${kmi:-?} kernel=$kernel -> $(basename "$ko")"
    # only arm64 KMI drivers are bundled; add a matching driver file for a new kernel.
    [ -f "$ko" ] || die "nomount driver unavailable for this kernel ($(basename "$ko"))"
    if [ -z "$version" ]; then
        "$MODPATH/bin/lkmloader" "$ko" || die "failed to load the nomount driver"
        version=$("$nm" version 2>/dev/null)
        [ -n "$version" ] || die "nomount driver is not responding after load"
    else
        step "existing nomount kernel module detected; staging driver for reboot"
    fi
    current=$(printf '%s\n' "$version" | sed -n '1s/^\([0-9][0-9]*\).*/\1/p')
    [ -n "$current" ] && [ "$current" -ge 22 ] || die "nomount driver v22+ required (found ${current:-none})"
    mv "$ko" "$MODPATH/lkm/nomount.ko" || die "cannot stage driver for reboot"
    logi "nomount driver v$current staged for reboot"
else
    current=$(printf '%s\n' "$version" | sed -n '1s/^\([0-9][0-9]*\).*/\1/p')
    [ -n "$current" ] && [ "$current" -ge 22 ] || die "nomount driver v22+ required (found ${current:-none})"
    rm -rf "$MODPATH/lkm"
    logi "nomount driver v$current already loaded"
fi

src=/system/build.prop
[ -f "$src" ] || src=/system/system/build.prop
[ -f "$src" ] || die "cannot read system build.prop"
device=$(getprop ro.product.device)
[ -n "$device" ] || device=$(getprop ro.product.name)
case "$device" in ''|*[!a-zA-Z0-9._-]*) die "invalid device name";; esac
case "$(getprop ro.product.mod_device)" in
    *_in_global*) mod="${device}_in_global";;
    *_ru_global*) mod="${device}_ru_global";;
    *_eea_global*) mod="${device}_eea_global";;
    *_global*) mod="${device}_global";;
    *) mod="$device";;
esac
sed -e 's/^ro\.build\.host=.*/ro.build.host=c5-build-66.bj.xiaomi.com/' \
    -e 's/^ro\.build\.type=userdebug/ro.build.type=user/' \
    -e 's/^ro\.debuggable=1/ro.debuggable=0/' \
    -e "s/^ro\.product\.mod_device=.*/ro.product.mod_device=$mod/" \
    -e '/# ADDED BY/d' -e '/MIUIOS\.CZ/d' -e '/MIUIPOLSKA\.PL/d' \
    -e '/^ro\.xiaomi\.developerid=/d' -e '/^ro\.xiaomi\.eu/d' \
    -e '/^ro\.\(tn\|hypertn\|eliterom\|mipa\|pulse\|lineage\|crdroid\)\./d' \
    -e '/^ro\.modversion=/d' "$src" > "$MODPATH/clean_build.prop" || die "cannot build clean property file"
chmod 644 "$MODPATH/clean_build.prop"
chcon u:object_r:system_file:s0 "$MODPATH/clean_build.prop" 2>/dev/null || true
rm -f "$MODPATH"/lkm/nomount-android*.ko
logi "clean build.prop built for device=$device mod_device=$mod (source $src)"

mkdir -p /data/adb/tricky_store || die "cannot create Tricky Store config directory"
chmod 700 /data/adb/tricky_store
for file in keybox.xml target.txt; do
    if [ ! -f "/data/adb/tricky_store/$file" ]; then
        cp "$MODPATH/tricky/$file" "/data/adb/tricky_store/$file" || die "cannot install $file"
        chmod 600 "/data/adb/tricky_store/$file"
        logi "installed default tricky_store/$file"
    fi
done
mv "$MODPATH/tricky/lib/arm64-v8a/libTrickyStoreOSS.so" "$MODPATH/tricky/libTrickyStoreOSS.so" || die "cannot install Tricky Store library"
mv "$MODPATH/tricky/lib/arm64-v8a/libinject.so" "$MODPATH/tricky/inject" || die "cannot install Tricky Store injector"
rm -rf "$MODPATH/tricky/lib"
chmod 755 "$MODPATH/tricky/daemon" "$MODPATH/tricky/inject" "$MODPATH/service.sh" "$MODPATH/uninstall.sh"

mkdir -p /data/adb/boot-completed.d || die "cannot create boot-completed.d"
rm -f /data/adb/boot-completed.d/leave-me-alone-hma.sh   # drop the legacy name from older installs
cp "$MODPATH/hma/hmaoss.sh" /data/adb/boot-completed.d/dont-mind-me-hma.sh || die "cannot install HMA status updater"
chmod 755 /data/adb/boot-completed.d/dont-mind-me-hma.sh
cp "$MODPATH/module.prop" "$MODPATH/module.prop.bak"
logi "tricky store, injector and boot-completed HMA hook installed"

# attestation patch must report the REAL firmware patch: GMS reads the real patch
# (via the per-app lib) while the live property is spoofed forward for banking apps,
# so pin Tricky's osPatchLevel to the real value or Play Integrity drops to BASIC
realpatch=$(sed -n 's/^ro\.build\.version\.security_patch=//p' "$src" | head -n 1)
[ -n "$realpatch" ] || realpatch=$(getprop ro.build.version.security_patch)
case "$realpatch" in
    20[0-9][0-9]-[0-1][0-9]-[0-3][0-9])
        [ -f /data/adb/tricky_store/security_patch.txt ] && cp -f /data/adb/tricky_store/security_patch.txt /data/adb/tricky_store/security_patch.txt.bak
        printf 'system=%s\nboot=%s\nvendor=%s\n' "$realpatch" "$realpatch" "$realpatch" > /data/adb/tricky_store/security_patch.txt
        chmod 600 /data/adb/tricky_store/security_patch.txt
        rm -rf /data/adb/tricky_store/keys/* 2>/dev/null
        step "attestation patch pinned to firmware value $realpatch"
        ;;
    *)
        logw "firmware security_patch unreadable or malformed ('${realpatch:-}'); left attestation patch untouched"
        ;;
esac

# property spoof switches ship with the module (all default ON); keep user's on upgrade
[ -f "$MODPATH/spoof.conf" ] || printf 'spoof_system=1\nspoof_fingerprint=1\nspoof_utc=1\nspoof_date=1\nspoof_os_patch=1\nspoof_vendor_patch=1\n' > "$MODPATH/spoof.conf"
chmod 644 "$MODPATH/spoof.conf"
chmod 755 "$MODPATH/spoof.sh"
chmod 755 "$MODPATH/fixnotify.sh"
# keep the notification-fix toggle across module updates
[ -f /data/adb/modules/dont_mind_me/.notifyfix ] && : > "$MODPATH/.notifyfix"
# the GMS process System.load()s this lib via the Bridge (packages/com.google.android.gms
# gates it in); system_lib_file lets the app domain dlopen/mmap-execute it through /proc/self/fd
chmod 644 "$MODPATH/gms/arm64-v8a/libgmsspoof.so"
chcon u:object_r:system_lib_file:s0 "$MODPATH/gms/arm64-v8a/libgmsspoof.so" 2>/dev/null || true
logi "spoof.conf, notification fix and GMS spoof library staged"

# this module bundles nomount + HMA (incl OSS) + Tricky Store (incl OSS) + PIF + property
# spoof + GMS patch, so auto-disable any separately installed copy to avoid slot/zygisk
# clashes. match by id or name so every build/variant is caught; keep dont_mind_me and the
# zygisk framework itself.
for d in /data/adb/modules/*/; do
    [ -f "$d/module.prop" ] || continue
    mid=$(sed -n 's/^id=//p' "$d/module.prop")
    case "$mid" in ''|dont_mind_me|zygisksu|rezygisk) continue;; esac
    mname=$(sed -n 's/^name=//p' "$d/module.prop")
    if printf '%s\n%s\n' "$mid" "$mname" | grep -qiE 'nomount|leave.?me.?alone|hide.?my.?app|hmaoss|hma[_-]|^hma$|tricky|playintegrit|^pif$|gms.?spoof|brene|tcb.?patch|duckusb'; then
        [ -f "$d/remove" ] && continue
        touch "$d/disable" && step "disabled conflicting module: $mid"
    fi
done
step "Don't mind me v$current staged (HMA, Tricky Store, nomount, spoof, GMS patch)"
logi "install finished"
