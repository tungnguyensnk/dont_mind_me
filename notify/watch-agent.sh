#!/system/bin/sh
# inotifyd agent for the MIUI/HyperOS notification fix.
#
# inotifyd calls this once per raw filesystem event in the watched settings directory, as:
#   watch-agent.sh <event-mask> <dir> <file>
# SettingsProvider commits a change by writing settings_system.xml via a temp file + rename,
# so the final rewrite shows up as the file "settings_system.xml". we react only to that,
# debounce bursts, then run the fix's repair step (which re-adds GMS if PowerKeeper has just
# dropped it). keeping this agent tiny matters because it is spawned for every raw event.
[ "$3" = settings_system.xml ] || exit 0
MODDIR=/data/adb/modules/dont_mind_me
TS="$MODDIR/.watch.ts"
now=$(date +%s)
last=$(cat "$TS" 2>/dev/null || echo 0)
[ "$((now - last))" -ge 2 ] || exit 0
echo "$now" > "$TS"
exec sh "$MODDIR/fixnotify.sh" repair
