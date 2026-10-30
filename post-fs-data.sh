#!/system/bin/sh
MODDIR=${0%/*}
[ -f "$MODDIR/disable" ] && exit 0
boot=$(cat /proc/sys/kernel/random/boot_id) || exit 1
if [ -s "$MODDIR/.booting" ] && [ "$(cat "$MODDIR/.booting")" != "$boot" ]; then
    touch "$MODDIR/disable"
    exit 1
fi
printf '%s\n' "$boot" > "$MODDIR/.booting"
nm="$MODDIR/bin/nm"
if ! "$nm" version >/dev/null 2>&1; then
    "$MODDIR/bin/lkmloader" "$MODDIR/lkm/nomount.ko" >/dev/null 2>&1 || {
        touch "$MODDIR/disable"
        exit 1
    }
fi
"$nm" version >/dev/null 2>&1 || { touch "$MODDIR/disable"; exit 1; }

