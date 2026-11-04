#!/system/bin/sh
set -eu
module=/data/adb/modules/dont_mind_me
conf=$module/spoof.conf
keys='spoof_system spoof_fingerprint spoof_utc spoof_date spoof_os_patch spoof_vendor_patch'
[ -f "$module/module.prop" ] || { echo 'not_installed' >&2; exit 1; }

# log every WebUI action and its outcome so a user-reported failure leaves a trace.
# logi/loge write only to the logfile (never stdout), so the WebUI's stdout parsing
# is untouched. fail() records the short error code before emitting it on stderr.
logi() { :; }; logw() { :; }; loge() { :; }
LOG_TAG=webui
[ -f "$module/log.sh" ] && . "$module/log.sh"
fail() { loge "hard $* failed"; echo "$1" >&2; exit 1; }
log=$module/dont_mind_me.log
install_log=$module/install.log
# newest-last list of existing log files (install + runtime, incl one rotation each).
# always return 0 so `files=$(logfiles)` can't trip set -e when the newest file is absent.
logfiles() { for f in "$install_log.old" "$install_log" "$log.old" "$log"; do [ -f "$f" ] && echo "$f"; done; return 0; }

action=${1:-}
logi "hard action='$action' arg='${2:-}'"
case "$action" in
    save)
        payload=${2:-}
        case "$payload" in ''|*[!a-zA-Z0-9+/=]*) fail bad_input;; esac
        [ "${#payload}" -le 4096 ] || fail input_too_big
        tmp=$(mktemp "$module/.spoof-XXXXXX") || fail save_fail
        trap 'rm -f "$tmp"' EXIT HUP INT TERM
        printf '%s' "$payload" | base64 -d > "$tmp" || fail decode_fail
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            ok=0
            for k in $keys; do [ "$line" = "$k=0" ] || [ "$line" = "$k=1" ] && { ok=1; break; }; done
            [ "$ok" = 1 ] || fail bad_flags
        done < "$tmp"
        chmod 644 "$tmp"
        mv -f "$tmp" "$conf" || fail save_fail
        trap - EXIT HUP INT TERM
        logi "spoof.conf saved: $(tr '\n' ' ' < "$conf")"
        echo 'ok'
        ;;
    adbset)
        case "${2:-}" in
            1) settings put global adb_enabled 1 && { logi 'adb debugging enabled'; echo 'ok'; };;
            0) settings put global adb_enabled 0 && { logi 'adb debugging disabled'; echo 'ok'; };;
            *) fail bad_value;;
        esac
        ;;
    notifyset)
        case "${2:-}" in
            1) : > "$module/.notifyfix"; sh "$module/fixnotify.sh" apply; logi 'notification fix enabled'; echo 'ok';;
            0) rm -f "$module/.notifyfix"; sh "$module/fixnotify.sh" revert; logi 'notification fix disabled'; echo 'ok';;
            *) fail bad_value;;
        esac
        ;;
    log)
        # tail of the combined install+runtime log for the WebUI's inline viewer
        n=${2:-200}
        case "$n" in ''|*[!0-9]*) n=200;; esac
        [ "$n" -le 5000 ] || n=5000
        files=$(logfiles)
        [ -n "$files" ] && cat $files 2>/dev/null | tail -n "$n" || true
        ;;
    export-log)
        # write a shareable diagnostic bundle (device info + full install log + 3 days of
        # runtime log) to shared storage so a user can retrieve it and send it back.
        ts=$(date +%Y%m%d-%H%M%S)
        name=dont_mind_me-log-$ts.txt
        file=
        for d in /sdcard/Download /sdcard /data/local/tmp; do
            [ -d "$d" ] || continue
            if : > "$d/$name" 2>/dev/null; then file=$d/$name; break; fi
        done
        [ -n "$file" ] || fail export_fail
        # 3-day cutoff as date prefixes (ISO dates sort lexicographically). if the device's
        # date can't do the arithmetic, fall back to the whole (rotation-bounded) runtime log.
        now=$(date +%s 2>/dev/null) || now=
        day() { d=$(date -d "@$((now-$1*86400))" +%Y-%m-%d 2>/dev/null) || d=$(date -D %s -d "$((now-$1*86400))" +%Y-%m-%d 2>/dev/null) || d=; echo "$d"; }
        d0=$(date +%Y-%m-%d); d1=; d2=
        [ -n "$now" ] && { d1=$(day 1); d2=$(day 2); } || :
        {
            echo '=== Dont mind me diagnostics ==='
            echo "exported : $(date '+%Y-%m-%d %H:%M:%S')"
            echo "module   : $(sed -n 's/^version=//p' "$module/module.prop") code $(sed -n 's/^versionCode=//p' "$module/module.prop")"
            echo "device   : $(getprop ro.product.manufacturer) $(getprop ro.product.model) [$(getprop ro.product.device)]"
            echo "android  : $(getprop ro.build.version.release) sdk $(getprop ro.build.version.sdk)"
            echo "patch    : $(getprop ro.build.version.security_patch)"
            echo "fp       : $(getprop ro.build.fingerprint)"
            echo "kernel   : $(uname -r)"
            echo "selinux  : $(getenforce 2>/dev/null)"
            echo "root     : ksu=$([ -d /data/adb/ksu ] && echo yes || echo no) apatch=$([ -d /data/adb/ap ] && echo yes || echo no)"
            echo "disabled : $([ -f "$module/disable" ] && echo yes || echo no)"
            echo
            echo '=== install.log ==='
            cat "$install_log.old" "$install_log" 2>/dev/null || echo '(none)'
            echo
            echo "=== runtime log (since ${d2:-start}) ==="
            if [ -n "$d1" ] && [ -n "$d2" ]; then
                cat "$log.old" "$log" 2>/dev/null | grep -E "^($d0|$d1|$d2)" || true
            else
                cat "$log.old" "$log" 2>/dev/null || true
            fi
        } >> "$file" 2>/dev/null || fail export_fail
        chmod 0644 "$file" 2>/dev/null || true
        logi "log exported to $file"
        printf '%s\n' "$file"
        ;;
    reboot)
        logi 'reboot requested'
        svc power reboot 2>/dev/null || /system/bin/reboot
        ;;
    *) fail bad_action ;;
esac
