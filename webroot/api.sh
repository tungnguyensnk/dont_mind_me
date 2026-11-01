#!/system/bin/sh
set -eu

module=/data/adb/modules/dont_mind_me
[ -f "$module/module.prop" ] || { echo 'not_installed' >&2; exit 1; }

dir=
for candidate in /data/misc/hide_my_applist_*; do
    [ -f "$candidate/status.json" ] || continue
    [ -z "$dir" ] || { echo 'hma_multi' >&2; exit 1; }
    dir=$candidate
done
[ -n "$dir" ] || { echo 'hma_no_data' >&2; exit 1; }
grep -q '"workMode":1' "$dir/status.json" || { echo 'hma_not_ready' >&2; exit 1; }

config=$dir/config.json
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
        case "$payload" in ''|*[!a-zA-Z0-9+/=]*) echo 'bad_input' >&2; exit 1;; esac
        [ "${#payload}" -le 131072 ] || { echo 'input_too_big' >&2; exit 1; }
        tmp=$(mktemp "$dir/.hma-webui-XXXXXX") || exit 1
        trap 'rm -f "$tmp"' EXIT HUP INT TERM
        printf '%s' "$payload" | base64 -d > "$tmp" || { echo 'decode_fail' >&2; exit 1; }
        [ -s "$tmp" ] || { echo 'empty_config' >&2; exit 1; }
        grep -q '"configVersion":93' "$tmp" && grep -q '"scope":{' "$tmp" || { echo 'bad_hma' >&2; exit 1; }
        chown 1000:1000 "$tmp"
        chmod 600 "$tmp"
        restorecon "$tmp" || { echo 'label_fail' >&2; exit 1; }
        if [ -f "$config" ]; then
            cp -p "$config" "$config.bak" || { echo 'backup_fail' >&2; exit 1; }
        fi
        mv -f "$tmp" "$config" || { echo 'save_fail' >&2; exit 1; }
        trap - EXIT HUP INT TERM
        printf '%s\n' 'ok'
        ;;
    *) echo 'bad_action' >&2; exit 1;;
esac
