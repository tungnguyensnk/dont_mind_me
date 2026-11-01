#!/system/bin/sh
# MIUI/HyperOS notification delay fix.
#
# Two things kill push on HyperOS CN:
#   1. the Greeze freezer can freeze Google Play Services, so its single FCM socket dies;
#   2. even unfrozen, that socket drops while the phone is idle/suspended and GMS's own
#      reconnect alarm is deferred for hours, so nothing arrives until an app is opened.
# GMS is the shared FCM deliverer, so fixing it fixes push for every app at once.
#
# Fix: keep GMS on the Settings.System key MILLET_NO_RESTRICT_APP (Greeze's exemption list,
# which PowerKeeper strips on battery/config/boot changes) and nudge GMS to reconnect on a
# schedule. The schedule runs from `hbd`, a CLOCK_BOOTTIME_ALARM timer that fires THROUGH
# deep sleep and wakes the device — a plain shell `sleep` loop is paused while suspended, so
# it never heartbeats overnight (that was the bug: woke to zero notifications).
#
# $1 = apply (default) | revert | beat. MIUI-only; a no-op elsewhere.

MODDIR=${0%/*}
MARKER="$MODDIR/.notifyfix"
HBD="$MODDIR/bin/hbd"
INTERVAL=600                       # seconds between FCM reconnect nudges (wakes from sleep)
GMS=com.google.android.gms
FCM="$GMS com.google.android.gsf com.android.vending"

is_miui() { [ -n "$(getprop ro.miui.ui.version.name)" ] || pm path com.miui.powerkeeper >/dev/null 2>&1; }

# current no-restrict list + the FCM stack, cleaned and de-duplicated (never drops the
# user's own Battery "No restrictions" entries). empty if settings couldn't be read.
merged_list() {
    cur=$(settings get system MILLET_NO_RESTRICT_APP 2>/dev/null)
    case "$cur" in null|'') cur= ;; *[!A-Za-z0-9._,\ ]*) return 0 ;; esac   # skip on a read error
    { printf '%s\n' "$cur" | tr ',' '\n'; for p in $FCM; do echo "$p"; done; } \
        | sed 's/[[:space:]]//g' | grep -E '^[A-Za-z0-9._]+$' | sort -u | paste -sd,
}

has_gms() {
    case ",$(settings get system MILLET_NO_RESTRICT_APP 2>/dev/null | sed 's/[[:space:]]//g')," in
        *,"$GMS",*) return 0 ;;
        *) return 1 ;;
    esac
}

apply_once() {
    l=$(merged_list)
    [ -n "$l" ] && settings put system MILLET_NO_RESTRICT_APP "$l" 2>/dev/null
}

# nudge GMS to reconnect / heartbeat its push socket; GMS takes these without a permission
heartbeat() {
    am broadcast -a com.google.android.intent.action.GCM_RECONNECT -p "$GMS" >/dev/null 2>&1
    am broadcast -a com.google.android.intent.action.MCS_HEARTBEAT -p "$GMS" >/dev/null 2>&1
}

# one tick, invoked by hbd on each wake: keep GMS exempt, then reconnect
beat() {
    [ -f "$MARKER" ] || return 0
    has_gms || apply_once
    heartbeat
}

start_keeper() {
    pgrep -x hbd >/dev/null 2>&1 && return 0
    [ -x "$HBD" ] || chmod 0755 "$HBD" 2>/dev/null
    setsid "$HBD" "$INTERVAL" /system/bin/sh "$MODDIR/fixnotify.sh" beat >/dev/null 2>&1 </dev/null &
}

stop_keeper() {
    for p in $(pgrep -x hbd 2>/dev/null); do kill "$p" 2>/dev/null || kill -9 "$p" 2>/dev/null; done
}

apply() {
    is_miui || return 0
    apply_once
    heartbeat
    start_keeper
}

# toggle off: stop the timer and drop only the FCM stack we added, keeping the user's own
# entries (PowerKeeper re-derives the rest from its Battery "No restrictions" list anyway)
revert() {
    stop_keeper
    cur=$(settings get system MILLET_NO_RESTRICT_APP 2>/dev/null)
    case "$cur" in ''|null|*[!A-Za-z0-9._,\ ]*) return 0 ;; esac
    new=$(printf '%s\n' "$cur" | tr ',' '\n' | sed 's/[[:space:]]//g' \
          | grep -vxE 'com\.google\.android\.gms|com\.google\.android\.gsf|com\.android\.vending' \
          | grep -E '^[A-Za-z0-9._]+$' | sort -u | paste -sd,)
    settings put system MILLET_NO_RESTRICT_APP "$new" 2>/dev/null
}

case "${1:-apply}" in
    revert) revert ;;
    beat) beat ;;
    *) apply ;;
esac
exit 0
