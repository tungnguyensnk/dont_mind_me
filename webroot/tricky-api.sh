#!/system/bin/sh
set -eu

config=/data/adb/tricky_store
module=/data/adb/modules/dont_mind_me
[ -f "$module/module.prop" ] || { echo 'not_installed' >&2; exit 1; }

# log each attestation action + outcome to the module logfile (never stdout, so the
# WebUI's stdout parsing stays intact). fail() records the short code then emits it.
logi() { :; }; logw() { :; }; loge() { :; }
LOG_TAG=webui
[ -f "$module/log.sh" ] && . "$module/log.sh"
fail() { loge "tricky $* failed"; echo "$1" >&2; exit 1; }
[ -d "$config" ] || fail ts_no_config

decode() {
    case "${1:-}" in
        ''|*[!a-zA-Z0-9+/=]*) fail bad_input;;
    esac
    [ "${#1}" -le 131072 ] || fail input_too_big
    printf '%s' "$1" | base64 -d
}

# clears cached attestation keys + GMS/target caches after every save (shared with install)
refresh_attestation() { :; }
[ -f "$module/refresh-attestation.sh" ] && . "$module/refresh-attestation.sh"

logi "tricky action='${1:-}'"
case "${1:-}" in
    open-keybox)
        am start -a android.intent.action.VIEW -d 'https://keybox.kowx712.cc' >/dev/null || fail browser_fail
        logi 'opened keybox download page'
        ;;
    save)
        tmp=$(mktemp "$config/.target-XXXXXX") || fail save_fail
        trap 'rm -f "$tmp"' EXIT HUP INT TERM
        decode "${2:-}" > "$tmp" || exit 1
        if grep -Ev '^[[:alnum:]_][[:alnum:]_.]*[!?]?$|^[[:space:]]*$|^[[:space:]]*#' "$tmp" | grep -q .; then
            fail bad_list
        fi
        chmod 600 "$tmp"
        if [ -f "$config/target.txt" ]; then
            cp -p "$config/target.txt" "$config/target.txt.bak" || fail backup_fail
        fi
        mv -f "$tmp" "$config/target.txt" || fail save_fail
        trap - EXIT HUP INT TERM
        logi "target.txt saved ($(grep -cvE '^[[:space:]]*(#|$)' "$config/target.txt" 2>/dev/null) entries); refreshing attestation"
        refresh_attestation
        echo 'ok'
        ;;
    set-keybox)
        # the WebUI base64-encodes the chosen XML file's contents and passes them here
        tmp=$(mktemp "$config/.keybox-XXXXXX") || fail save_fail
        trap 'rm -f "$tmp"' EXIT HUP INT TERM
        decode "${2:-}" > "$tmp" || exit 1
        [ -s "$tmp" ] && [ "$(wc -c < "$tmp")" -le 65536 ] || fail kb_bad_size
        for tag in AndroidAttestation Keybox PrivateKey CertificateChain Certificate; do
            grep -q "<$tag[ >]" "$tmp" && grep -q "</$tag>" "$tmp" || fail kb_missing_tags
        done
        if grep -iEq '<!DOCTYPE|<!ENTITY' "$tmp"; then
            fail kb_dtd
        fi
        chmod 600 "$tmp"
        if [ -f "$config/keybox.xml" ]; then
            cp -p "$config/keybox.xml" "$config/keybox.xml.bak" || fail backup_fail
        fi
        mv -f "$tmp" "$config/keybox.xml" || fail save_fail
        trap - EXIT HUP INT TERM
        logi 'keybox.xml installed; refreshing attestation'
        refresh_attestation
        echo 'ok'
        ;;
    patch)
        command -v curl >/dev/null 2>&1 || fail no_curl
        tmp=$(mktemp "$config/.bulletin-XXXXXX") || fail save_fail
        trap 'rm -f "$tmp"' EXIT HUP INT TERM
        curl -fLsS --connect-timeout 10 --max-time 25 'https://source.android.com/docs/security/bulletin/pixel' > "$tmp" || fail bulletin_fail
        patch=$(grep -oE '<td>20[0-9]{2}-(0[1-9]|1[0-2])-0[15]</td>' "$tmp" | sed 's/<[^>]*>//g' | sort -r | head -n 1) || true
        [ -n "$patch" ] || fail patch_fetch_fail
        logi "fetched latest pixel patch date: $patch"
        printf '%s\n' "$patch"
        ;;
    set-patch)
        patch=${2:-}
        printf '%s\n' "$patch" | grep -Eq '^20[0-9]{2}-(0[1-9]|1[0-2])-0[15]$' || fail patch_bad
        # system patch must stay the REAL firmware value: GMS reads the real patch via
        # libgmsspoof, so the forged attestation's osPatchLevel must match it or Play
        # Integrity drops below STRONG. only boot/vendor follow the chosen recent date.
        real=$(sed -n 's/^ro\.build\.version\.security_patch=//p' /system/build.prop /system/system/build.prop 2>/dev/null | head -n 1)
        case "$real" in 20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]) ;; *) real=$patch ;; esac
        tmp=$(mktemp "$config/.patch-XXXXXX") || fail save_fail
        trap 'rm -f "$tmp"' EXIT HUP INT TERM
        printf 'system=%s\nboot=%s\nvendor=%s\n' "$real" "$patch" "$patch" > "$tmp"
        chmod 600 "$tmp"
        if [ -f "$config/security_patch.txt" ]; then
            cp -p "$config/security_patch.txt" "$config/security_patch.txt.bak" || fail backup_fail
        fi
        mv -f "$tmp" "$config/security_patch.txt" || fail save_fail
        trap - EXIT HUP INT TERM
        logi "patch set: system=$real boot=$patch vendor=$patch; refreshing attestation"
        refresh_attestation
        echo 'ok'
        ;;
    *) fail bad_action;;
esac
