#!/system/bin/sh
# shared helper: drop the cached attestation keys and clear the CACHE (never data) of
# GMS + every target app, then stop them so they fetch a fresh Play Integrity verdict
# on next launch. clearing data would wipe logins, so we never touch it.
# sourced by webroot/tricky-api.sh (after every save) and by customize.sh (on install).
refresh_attestation() {
    _ts=/data/adb/tricky_store
    rm -rf "$_ts/keys/"* 2>/dev/null
    for _pkg in com.google.android.gms $(grep -vE '^[[:space:]]*(#|$)' "$_ts/target.txt" 2>/dev/null | sed 's/[[:space:]]//g; s/[!?]*$//'); do
        case "$_pkg" in ''|*[!a-zA-Z0-9._]*) continue;; esac
        rm -rf "/data/data/$_pkg/cache/"* "/data/data/$_pkg/code_cache/"* 2>/dev/null
        am force-stop "$_pkg" 2>/dev/null
    done
    return 0
}
