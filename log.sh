#!/system/bin/sh
# shared timestamped logger for the install and boot/runtime scripts.
# usage: set LOG_TAG (and optionally LOGFILE) then source this file, e.g.
#        LOG_TAG=service; . "$MODDIR/log.sh"; logi "message"
# levels: logi (INFO) / logw (WARN) / loge (ERROR). every call is best-effort and
# never fails its caller, so sourcing or logging can't break an early-boot script.
LOG_TAG=${LOG_TAG:-dmm}
LOGFILE=${LOGFILE:-/data/adb/modules/dont_mind_me/dont_mind_me.log}

# keep one rotation so repeated boots can't grow the log without bound (~256 KiB)
if [ -f "$LOGFILE" ] && [ "$(wc -c < "$LOGFILE" 2>/dev/null || echo 0)" -gt 262144 ]; then
    mv -f "$LOGFILE" "$LOGFILE.old" 2>/dev/null || true
fi

log() {
    _lvl=$1
    shift
    printf '%s [%s] %-5s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$LOG_TAG" "$_lvl" "$*" >> "$LOGFILE" 2>/dev/null || true
}
logi() { log INFO "$@"; }
logw() { log WARN "$@"; }
loge() { log ERROR "$@"; }
