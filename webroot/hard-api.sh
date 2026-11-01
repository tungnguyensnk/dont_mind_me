#!/system/bin/sh
set -eu
module=/data/adb/modules/dont_mind_me
conf=$module/spoof.conf
keys='spoof_system spoof_fingerprint spoof_utc spoof_date spoof_os_patch spoof_vendor_patch'
[ -f "$module/module.prop" ] || { echo 'not_installed' >&2; exit 1; }
case "${1:-}" in
    save)
        payload=${2:-}
        case "$payload" in ''|*[!a-zA-Z0-9+/=]*) echo 'bad_input' >&2; exit 1;; esac
        [ "${#payload}" -le 4096 ] || { echo 'input_too_big' >&2; exit 1; }
        tmp=$(mktemp "$module/.spoof-XXXXXX") || exit 1
        trap 'rm -f "$tmp"' EXIT HUP INT TERM
        printf '%s' "$payload" | base64 -d > "$tmp" || { echo 'decode_fail' >&2; exit 1; }
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            ok=0
            for k in $keys; do [ "$line" = "$k=0" ] || [ "$line" = "$k=1" ] && { ok=1; break; }; done
            [ "$ok" = 1 ] || { echo 'bad_flags' >&2; exit 1; }
        done < "$tmp"
        chmod 644 "$tmp"
        mv -f "$tmp" "$conf" || { echo 'save_fail' >&2; exit 1; }
        trap - EXIT HUP INT TERM
        echo 'ok'
        ;;
    adbset)
        case "${2:-}" in
            1) settings put global adb_enabled 1 && echo 'ok';;
            0) settings put global adb_enabled 0 && echo 'ok';;
            *) echo 'bad_value' >&2; exit 1;;
        esac
        ;;
    notifyset)
        case "${2:-}" in
            1) : > "$module/.notifyfix"; sh "$module/fixnotify.sh" apply; echo 'ok';;
            0) rm -f "$module/.notifyfix"; sh "$module/fixnotify.sh" revert; echo 'ok';;
            *) echo 'bad_value' >&2; exit 1;;
        esac
        ;;
    reboot)
        svc power reboot 2>/dev/null || /system/bin/reboot
        ;;
    *) echo 'bad_action' >&2; exit 1 ;;
esac
