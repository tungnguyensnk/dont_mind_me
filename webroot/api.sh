#!/system/bin/sh
set -eu

module=/data/adb/modules/dont_mind_me
[ -f "$module/module.prop" ] || { echo 'not_installed' >&2; exit 1; }

# log each HMA action + outcome to the module logfile (never stdout, so the WebUI's
# stdout parsing stays intact). fail() records the short code then emits it on stderr.
logi() { :; }; logw() { :; }; loge() { :; }
LOG_TAG=webui
[ -f "$module/log.sh" ] && . "$module/log.sh"
fail() { loge "hma $* failed"; echo "$1" >&2; exit 1; }

dir=
for candidate in /data/misc/hide_my_applist_*; do
    [ -f "$candidate/status.json" ] || continue
    [ -z "$dir" ] || fail hma_multi
    dir=$candidate
done
[ -n "$dir" ] || fail hma_no_data
grep -q '"workMode":1' "$dir/status.json" || fail hma_not_ready

config=$dir/config.json
logi "hma action='${1:-}' dir='$dir'"
case "${1:-}" in
    bundle)
        # one round-trip for the WebUI's initial load: user-app list plus the three
        # configs (targets, HMA scope, spoof flags) and the ADB/notify flags, joined
        # by ===MARKER=== lines the WebUI splits on. keeps the call count to one.
        printf '%s\n' '===LIST==='
        cmd package list packages -3 --user 0 | sed -n 's/^package://p' | sort -u
        printf '%s\n' '===TARGETS==='
        [ -f /data/adb/tricky_store/target.txt ] && cat /data/adb/tricky_store/target.txt
        printf '%s\n' '===HMA==='
        if [ -f "$config" ]; then cat "$config"; else printf '%s\n' '{"configVersion":93,"scope":{}}'; fi
        printf '\n%s\n' '===HARD==='
        if [ -f "$module/spoof.conf" ]; then cat "$module/spoof.conf"; else printf 'spoof_system=1\nspoof_fingerprint=1\nspoof_utc=1\nspoof_date=1\nspoof_os_patch=1\nspoof_vendor_patch=1\n'; fi
        printf '\n%s\n' '===ADB==='
        v=$(settings get global adb_enabled 2>/dev/null); case "$v" in 1) echo 1;; *) echo 0;; esac
        printf '\n%s\n' '===NOTIFY==='
        [ -f "$module/.notifyfix" ] && echo 1 || echo 0
        ;;
    save)
        payload=${2:-}
        case "$payload" in ''|*[!a-zA-Z0-9+/=]*) fail bad_input;; esac
        [ "${#payload}" -le 131072 ] || fail input_too_big
        tmp=$(mktemp "$dir/.hma-webui-XXXXXX") || fail save_fail
        trap 'rm -f "$tmp"' EXIT HUP INT TERM
        printf '%s' "$payload" | base64 -d > "$tmp" || fail decode_fail
        [ -s "$tmp" ] || fail empty_config
        grep -q '"configVersion":93' "$tmp" && grep -q '"scope":{' "$tmp" || fail bad_hma
        chown 1000:1000 "$tmp"
        chmod 600 "$tmp"
        restorecon "$tmp" || fail label_fail
        if [ -f "$config" ]; then
            cp -p "$config" "$config.bak" || fail backup_fail
        fi
        mv -f "$tmp" "$config" || fail save_fail
        trap - EXIT HUP INT TERM
        logi "hma config saved ($(wc -c < "$config" 2>/dev/null) bytes)"
        printf '%s\n' 'ok'
        ;;
    *) fail bad_action;;
esac
