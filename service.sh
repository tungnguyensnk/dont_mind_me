#!/system/bin/sh
MODDIR=${0%/*}
logi() { :; }; logw() { :; }; loge() { :; }
LOG_TAG=service
[ -f "$MODDIR/log.sh" ] && . "$MODDIR/log.sh"

decode_numbers() {
    printf '\143\157\155\056\166\156\151\144\n'
}
[ -f "$MODDIR/disable" ] && { logi "module disabled, skipping"; exit 0; }
logi "service start (kernel=$(uname -r) android=$(getprop ro.build.version.release) sdk=$(getprop ro.build.version.sdk))"
[ -f "$MODDIR/tricky/prop.sh" ] && { sh "$MODDIR/tricky/prop.sh" & logi "tricky prop.sh launched (pid $!)"; }
(
    cd "$MODDIR/tricky" || { loge "tricky dir missing; daemon not started"; exit 1; }
    # wait until the framework is up so keystore2's binder backdoor is registrable;
    # injecting too early at boot fails (permission denied), so keep retrying instead
    # of giving up — the daemon stays resident once it attaches.
    until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 1; done
    sleep 5
    _try=0
    while true; do
        _try=$((_try + 1))
        logi "tricky daemon starting (attempt $_try)"
        ./daemon "$MODDIR/tricky"
        logw "tricky daemon exited (code $?); restarting in 5s"
        sleep 5
    done
) &
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 1; done
# hide system crash report dialogs after boot
settings put global hide_error_dialogs 1 >/dev/null 2>&1
rm -f "$MODDIR/.booting"
logi "boot completed; running post-boot tasks"

# run the one-shot property spoof pass after boot
if [ -f "$MODDIR/spoof.conf" ]; then
    logi "running spoof.sh"
    sh "$MODDIR/spoof.sh"
else
    logw "spoof.conf missing; skipped property spoof"
fi

nm="$MODDIR/bin/nm"
"$nm" version >/dev/null 2>&1 || exit 1

resetprop=/data/adb/ksu/bin/resetprop
[ -x "$resetprop" ] || resetprop=/data/adb/ap/bin/resetprop
if [ -x "$resetprop" ]; then
    "$resetprop" -n -v ro.build.host c5-build-66.bj.xiaomi.com
    mod=$(sed -n 's/^ro\.product\.mod_device=//p' "$MODDIR/clean_build.prop" | head -n 1)
    [ -n "$mod" ] && "$resetprop" -n -v ro.product.mod_device "$mod"
    [ "$(getprop ro.build.type)" = userdebug ] && "$resetprop" -n -v ro.build.type user
    [ "$(getprop ro.debuggable)" = 1 ] && "$resetprop" -n -v ro.debuggable 0
    for key in $(getprop | sed -n 's/^\[\([^]]*\)\]:.*$/\1/p' | grep -iE 'xiaomi\.eu|developerid|hypertn|eliterom|mipa|pulse|lineage|modversion'); do
        "$resetprop" -n -v -d "$key" 2>/dev/null
    done
    logi "applied live resetprop build overrides"
else
    logw "resetprop not found; skipped live prop overrides"
fi

# hide rules cover the main app UID; add more package UIDs if its process model changes.
until cmd package list packages >/dev/null 2>&1; do sleep 1; done

# MIUI notification fix (opt-in via WebUI): re-apply each boot since the settings reset
[ -f "$MODDIR/.notifyfix" ] && sh "$MODDIR/fixnotify.sh" apply

uid=$(cmd package list packages -U "$(decode_numbers)" | sed -n "s/^package:$(decode_numbers) uid:\([0-9][0-9]*\)\$/\1/p" | head -n 1)
[ -n "$uid" ] || { logi "target app not installed; no hide rules applied"; exit 0; }
logi "applying hide rules for target uid=$uid"

if [ -f "$MODDIR/clean_build.prop" ]; then
    "$nm" rule add --uid "$uid" /system/build.prop "$MODDIR/clean_build.prop"
    [ -f /system/system/build.prop ] && "$nm" rule add --uid "$uid" /system/system/build.prop "$MODDIR/clean_build.prop"
    logi "build.prop redirect rule added"
else
    logw "clean_build.prop missing; build.prop not redirected"
fi
rules=0
for path in /system/addon.d $(find /system /product /system_ext /vendor \
        \( -iname '*lineage*' -o -iname '*crdroid*' -o -iname '*xiaomieu*' \
           -o -iname '*hypertn*' -o -iname '*eliterom*' -o -iname '*mipa*' \) \
        -prune -print 2>/dev/null); do
    [ -e "$path" ] && { "$nm" rule add --whiteout "$path" --uid "$uid"; rules=$((rules + 1)); logi "whiteout rule: $path"; }
done
logi "service done ($rules custom-rom path(s) hidden from uid=$uid)"
