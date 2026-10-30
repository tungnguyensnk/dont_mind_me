#!/system/bin/sh
# BRENE minimal: property spoofing only, ported faithfully from BRENE utils.sh.
# every spoof is an independent switch in spoof.conf so each can be toggled to
# find which ones an app actually needs. no path/mount hiding, no ksu-dir
# hiding, no kernel features -> adb shell su stays intact.
MODDIR=${0%/*}
RESETPROP=/data/adb/ksu/bin/resetprop
[ -x "$RESETPROP" ] || RESETPROP=/data/adb/ap/bin/resetprop
[ -x "$RESETPROP" ] || RESETPROP=resetprop
LOG="$MODDIR/spoof.log"

# all switches default off; spoof.conf turns them on
spoof_system=0; spoof_fingerprint=0; spoof_utc=0; spoof_date=0; spoof_os_patch=0; spoof_vendor_patch=0
[ -f "$MODDIR/spoof.conf" ] && . "$MODDIR/spoof.conf"

on() { eval "[ \"\${$1:-0}\" = 1 ]"; }
resetprop_n() { "$RESETPROP" -n "$1" "$2"; }
# set only when the prop exists and differs (BRENE if_prop_exits_resetprop_n)
if_prop() {
    cur=$("$RESETPROP" "$1")
    [ -z "$cur" ] && return 0
    [ "$cur" = "$2" ] && return 0
    "$RESETPROP" -n "$1" "$2"
}

do_system() {
    if_prop ro.secure 1
    if_prop ro.debuggable 0
    if_prop ro.adb.secure 1
    if_prop persist.sys.usb.config mtp
    if_prop ro.boot.verifiedbootstate green
    if_prop ro.boot.flash.locked 1
    if_prop ro.boot.veritymode enforcing
    if_prop ro.boot.avb_version 1.3
    if_prop ro.build.type user
    if_prop ro.build.tags release-keys
    if_prop ro.build.keys release-keys
    if_prop ro.allow.mock.location 0
    if_prop ro.boot.warranty_bit 0
    if_prop ro.warranty_bit 0
    if_prop ro.force.debuggable 0
    if_prop ro.secureboot.devicelock 1
    if_prop ro.secureboot.lockstate locked
    if_prop ro.is_ever_orange 0
    if_prop ro.bootmode normal
    if_prop vendor.boot.verifiedbootstate green
    if_prop ro.vendor.boot.warranty_bit 0
    if_prop ro.vendor.warranty_bit 0
    if_prop init.svc.adbd stopped
    if_prop init.svc_debug_pid.adbd ""
    if_prop ro.oem_unlock_supported 0
    # Realme
    if_prop ro.boot.realme.lockstate 1
    if_prop ro.boot.realmebootstate green
    slot=$("$RESETPROP" ro.boot.slot_suffix)
    size=$(blockdev --getsize64 "/dev/block/by-name/vbmeta${slot}" 2>/dev/null)
    [ -n "$size" ] && resetprop_n ro.boot.vbmeta.size "$size"
    resetprop_n ro.boot.vbmeta.avb_version 1.3
    resetprop_n ro.boot.vbmeta.hash_alg sha256
    resetprop_n ro.boot.vbmeta.device_state locked
    resetprop_n ro.boot.vbmeta.invalidate_on_error yes
    resetprop_n vendor.boot.vbmeta.device_state locked
    # delete some prop names for newer pixel device
    for k in ro.boot.verifiedbooterror ro.boot.verifyerrorpart vendor.boot.verifyerrorpart \
             vendor.boot.verifiedbooterror crashrecovery.rescue_boot_count \
             service.adb.root service.adb.tcp.port; do
        "$RESETPROP" -d "$k" 2>/dev/null
    done
    if [ "$("$RESETPROP" ro.build.version.sdk)" -ge 36 ] 2>/dev/null; then
        "$RESETPROP" -d sys.oem_unlock_allowed 2>/dev/null
    else
        if_prop sys.oem_unlock_allowed 0
    fi
}

do_fingerprint() {
    fp=$("$RESETPROP" ro.build.fingerprint)
    nfp=$(printf '%s' "$fp" | sed -e 's/userdebug/user/g' -e 's/evolution//g' -e 's/crdroid//g' -e 's/lineage//g')
    for p in ro.bootimage.build.fingerprint ro.build.fingerprint ro.odm.build.fingerprint \
             ro.odm_dlkm.build.fingerprint ro.product.build.fingerprint ro.system.build.fingerprint \
             ro.system_dlkm.build.fingerprint ro.system_ext.build.fingerprint \
             ro.vendor.build.fingerprint ro.vendor_dlkm.build.fingerprint; do
        if_prop "$p" "$nfp"
    done
}

do_utc() {
    utc=$("$RESETPROP" ro.build.date.utc)
    for p in ro.bootimage.build.date.utc ro.build.date.utc ro.odm.build.date.utc \
             ro.odm_dlkm.build.date.utc ro.product.build.date.utc ro.system.build.date.utc \
             ro.system_dlkm.build.date.utc ro.system_ext.build.date.utc \
             ro.vendor.build.date.utc ro.vendor_dlkm.build.date.utc persist.vendor.build.date.utc; do
        if_prop "$p" "$utc"
    done
}

do_date() {
    bd=$("$RESETPROP" ro.build.date)
    for p in ro.bootimage.build.date ro.build.date ro.odm.build.date ro.odm_dlkm.build.date \
             ro.product.build.date ro.system.build.date ro.system_dlkm.build.date \
             ro.system_ext.build.date ro.vendor.build.date ro.vendor_dlkm.build.date; do
        if_prop "$p" "$bd"
    done
}

# os/vendor patch move to an always-recent date (same date math as BRENE)
patch_date() { # $1 = day-of-month suffix (01 for os, 05 for vendor)
    y=$(date +%Y); m=$(date +%m); d=$(date +%d)
    if [ "$d" -ge 5 ] 2>/dev/null; then
        echo "${y}-${m}-$1"
    elif [ "$m" -ge 2 ] 2>/dev/null; then
        echo "${y}-$(printf '%02d' $((10#$m - 1)))-$1"
    else
        echo "$((y - 1))-12-$1"
    fi
}
do_os_patch() { if_prop ro.build.version.security_patch "$(patch_date 01)"; }
do_vendor_patch() { if_prop ro.vendor.build.security_patch "$(patch_date 05)"; }

echo "$(date) spoof start" >> "$LOG"
on spoof_system && do_system
on spoof_fingerprint && do_fingerprint
on spoof_utc && do_utc
on spoof_date && do_date
on spoof_os_patch && do_os_patch
on spoof_vendor_patch && do_vendor_patch
"$RESETPROP" -c --force 2>/dev/null || "$RESETPROP" -c 2>/dev/null || true
echo "$(date) spoof done" >> "$LOG"
