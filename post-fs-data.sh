#!/system/bin/sh
MODDIR=${0%/*}
logi() { :; }; logw() { :; }; loge() { :; }
LOG_TAG=post-fs-data
[ -f "$MODDIR/log.sh" ] && . "$MODDIR/log.sh"
[ -f "$MODDIR/disable" ] && { logi "module disabled, skipping"; exit 0; }
boot=$(cat /proc/sys/kernel/random/boot_id) || { loge "cannot read boot_id"; exit 1; }
# if the marker from the previous boot was never cleared, service.sh did not finish
# last time (likely a crash) — self-disable so a boot loop can't brick the device.
if [ -s "$MODDIR/.booting" ] && [ "$(cat "$MODDIR/.booting")" != "$boot" ]; then
    loge "previous boot did not complete service.sh; self-disabling"
    touch "$MODDIR/disable"
    exit 1
fi
printf '%s\n' "$boot" > "$MODDIR/.booting"
logi "post-fs-data start (boot_id=$boot)"
nm="$MODDIR/bin/nm"
if ! "$nm" version >/dev/null 2>&1; then
    logw "nomount driver not responding; loading lkm/nomount.ko"
    "$MODDIR/bin/lkmloader" "$MODDIR/lkm/nomount.ko" >/dev/null 2>&1 || {
        loge "failed to load nomount driver; self-disabling"
        touch "$MODDIR/disable"
        exit 1
    }
fi
"$nm" version >/dev/null 2>&1 || { loge "nomount driver still not responding; self-disabling"; touch "$MODDIR/disable"; exit 1; }
logi "post-fs-data done; nomount driver active (v$("$nm" version 2>/dev/null | head -n 1))"
