#!/system/bin/sh

# ref: https://github.com/PerformanC/ReZygisk/blob/main/module/src/rezygisk.sh

set -e

MODDIR=/data/adb/modules/dont_mind_me
[ -f "$MODDIR/module.prop.bak" ] && cp "$MODDIR/module.prop.bak" "$MODDIR/module.prop"
true
