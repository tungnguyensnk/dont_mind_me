#!/system/bin/sh
# shared helper: force a fresh Play Integrity verdict after a keybox/patch/target change,
# without the collateral battery cost the old version caused.
#
# it drops the TrickyStore attestation keys and the GMS DroidGuard cache (the only GMS state
# that affects the verdict) and restarts ONLY the DroidGuard process. it deliberately does
# NOT wipe the whole com.google.android.gms cache nor force-stop the entire GMS package:
# doing that cold-rebuilds unrelated GMS subsystems (Wearable, Measurement, ...), which pins
# GMS CPU and drains the battery for minutes after every save. target (banking) apps still
# get their cache cleared + stopped so they re-fetch a verdict on next launch.
# never touches app DATA (that would wipe logins).
# sourced by webroot/tricky-api.sh (after every save) and by customize.sh (on install).
refresh_attestation() {
    _ts=/data/adb/tricky_store
    rm -rf "$_ts/keys/"* 2>/dev/null

    # fresh DroidGuard attestation: drop its cache for every user, restart just that process
    for _d in /data/user/*/com.google.android.gms; do
        [ -d "$_d" ] && rm -rf "$_d/app_dg_cache/"* 2>/dev/null
    done
    _dg=$(pidof com.google.android.gms.unstable 2>/dev/null)
    [ -n "$_dg" ] && kill $_dg 2>/dev/null

    # target (banking) apps: clear cache + stop so they re-check integrity next launch
    for _pkg in $(grep -vE '^[[:space:]]*(#|$)' "$_ts/target.txt" 2>/dev/null | sed 's/[[:space:]]//g; s/[!?]*$//'); do
        case "$_pkg" in ''|*[!a-zA-Z0-9._]*) continue;; esac
        rm -rf "/data/data/$_pkg/cache/"* "/data/data/$_pkg/code_cache/"* 2>/dev/null
        am force-stop "$_pkg" 2>/dev/null
    done
    return 0
}
