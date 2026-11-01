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
# which PowerKeeper strips on battery/config/boot changes). two mechanisms maintain it:
#   - `hbd`, a CLOCK_BOOTTIME_ALARM timer that fires THROUGH deep sleep (a plain shell `sleep`
#     loop is paused while suspended, so it never heartbeats overnight) to re-add GMS if
#     needed and nudge the push socket to reconnect;
#   - `inotifyd`, a watcher on the settings file that re-adds GMS within ~1s of PowerKeeper
#     dropping it, so push does not wait up to a full timer interval to recover.
#
# $1 = apply (default) | revert | beat | repair. MIUI-only; a no-op elsewhere.

MODDIR=${0%/*}
# inotifyd runs its agent with a minimal environment, so give every caller a sane PATH;
# harmless for the boot/WebUI callers that already have one
export PATH=/system/bin:/system/xbin:/vendor/bin${PATH:+:$PATH}
logi() { :; }; logw() { :; }; loge() { :; }
LOG_TAG=notify
[ -f "$MODDIR/log.sh" ] && . "$MODDIR/log.sh"
MARKER="$MODDIR/.notifyfix"
HBD="$MODDIR/bin/hbd"
INTERVAL=1200                      # seconds between FCM reconnect nudges (wakes from sleep)
WATCHAGENT="$MODDIR/notify/watch-agent.sh"   # inotifyd agent (see start_watcher)
WATCHDIR=/data/system/users/0                # SettingsProvider persists system settings here
WATCHPID="$MODDIR/.watch.pid"                # pid of the inotifyd watcher
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

# a cheap nudge: GCM_RECONNECT re-establishes the push socket only if it is actually down,
# and is a no-op while the socket is alive, so it is safe to send every tick without waking
# the radio when nothing is wrong. GMS takes it without a permission.
reconnect() {
    am broadcast -a com.google.android.intent.action.GCM_RECONNECT -p "$GMS" >/dev/null 2>&1
}

# a full heartbeat also forces GMS to send a keepalive packet right now, which wakes the
# radio; only worth it just after GMS was unfrozen, when its push socket was torn down
heartbeat() {
    reconnect
    am broadcast -a com.google.android.intent.action.MCS_HEARTBEAT -p "$GMS" >/dev/null 2>&1
}

# one tick, invoked by hbd on each wake. if GMS is still exempt its socket should be alive,
# so send only the cheap reconnect; reserve the full heartbeat for when PowerKeeper has just
# stripped GMS and we re-add it, to avoid waking the radio on every tick for nothing
beat() {
    [ -f "$MARKER" ] || return 0
    if has_gms; then
        reconnect
    else
        apply_once
        heartbeat
    fi
    start_watcher   # relaunch the event-driven watcher if it has died since the last tick
}

# event-driven repair, fired by the inotifyd watcher when the settings file is rewritten.
# unlike beat it never sends a reconnect on its own (it runs on every settings change, not on
# a schedule), so it only acts when GMS was actually dropped — then it re-adds and reconnects.
repair() {
    [ -f "$MARKER" ] || return 0
    has_gms || { apply_once; heartbeat; }
}

start_keeper() {
    pgrep -x hbd >/dev/null 2>&1 && return 0
    [ -x "$HBD" ] || chmod 0755 "$HBD" 2>/dev/null
    setsid "$HBD" "$INTERVAL" /system/bin/sh "$MODDIR/fixnotify.sh" beat >/dev/null 2>&1 </dev/null &
    logi "heartbeat daemon launched (interval=${INTERVAL}s)"
}

stop_keeper() {
    for p in $(pgrep -x hbd 2>/dev/null); do kill "$p" 2>/dev/null || kill -9 "$p" 2>/dev/null; done
}

# event-driven half: an inotifyd watcher on the settings directory that runs `repair` the
# instant PowerKeeper strips GMS, so push recovers in ~1s instead of waiting for the next hbd
# tick. no installed app is involved. the hbd timer is the fallback, so a missing inotifyd or
# a failed launch only loses the fast reaction, never the fix itself.
start_watcher() {
    command -v inotifyd >/dev/null 2>&1 || return 0
    [ -x "$WATCHAGENT" ] || chmod 0755 "$WATCHAGENT" 2>/dev/null
    [ -f "$WATCHAGENT" ] && [ -d "$WATCHDIR" ] || return 0
    if [ -f "$WATCHPID" ] && kill -0 "$(cat "$WATCHPID" 2>/dev/null)" 2>/dev/null; then
        return 0
    fi
    setsid inotifyd "$WATCHAGENT" "$WATCHDIR" >/dev/null 2>&1 </dev/null &
    echo $! > "$WATCHPID"
    logi "settings watcher launched (pid $(cat "$WATCHPID" 2>/dev/null))"
}

stop_watcher() {
    [ -f "$WATCHPID" ] || return 0
    _p=$(cat "$WATCHPID" 2>/dev/null)
    [ -n "$_p" ] && { kill "$_p" 2>/dev/null || kill -9 "$_p" 2>/dev/null; }
    rm -f "$WATCHPID"
}

apply() {
    is_miui || { logi "not a MIUI/HyperOS device; notification fix skipped"; return 0; }
    apply_once
    heartbeat
    start_keeper
    start_watcher
    logi "notification fix applied (GMS kept exempt, timer + settings watcher running)"
}

# toggle off: stop the timer and drop only the FCM stack we added, keeping the user's own
# entries (PowerKeeper re-derives the rest from its Battery "No restrictions" list anyway)
revert() {
    logi "reverting notification fix"
    stop_keeper
    stop_watcher
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
    repair) repair ;;
    *) apply ;;
esac
exit 0
