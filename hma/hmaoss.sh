#!/system/bin/sh

# boot-completed hook: restore the original module.prop after the HMA runtime
# appends its status line to the live description.

set -e

MODDIR=/data/adb/modules/dont_mind_me
[ -f "$MODDIR/module.prop.bak" ] && cp "$MODDIR/module.prop.bak" "$MODDIR/module.prop"
true
