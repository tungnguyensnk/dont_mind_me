#!/system/bin/sh
set -eu

config=/data/adb/tricky_store
module=/data/adb/modules/dont_mind_me
downloads=/storage/emulated/0/Download
[ -f "$module/module.prop" ] || { echo 'not_installed' >&2; exit 1; }
[ -d "$config" ] || { echo 'ts_no_config' >&2; exit 1; }

decode() {
    case "${1:-}" in
        ''|*[!a-zA-Z0-9+/=]*) echo 'bad_input' >&2; exit 1;;
    esac
    [ "${#1}" -le 131072 ] || { echo 'input_too_big' >&2; exit 1; }
    printf '%s' "$1" | base64 -d
}

# after a TrickyStore setting changes, drop the cached attestation keys and clear the
# CACHE (never data) of GMS + every target app, then stop them so they fetch a fresh
# Play Integrity verdict on next launch. clearing data would wipe logins, so we don't.
refresh_attestation() {
    rm -rf "$config/keys/"* 2>/dev/null
    for pkg in com.google.android.gms $(grep -vE '^[[:space:]]*(#|$)' "$config/target.txt" 2>/dev/null | sed 's/[[:space:]]//g; s/[!?]*$//'); do
        case "$pkg" in ''|*[!a-zA-Z0-9._]*) continue;; esac
        rm -rf "/data/data/$pkg/cache/"* "/data/data/$pkg/code_cache/"* 2>/dev/null
        am force-stop "$pkg" 2>/dev/null
    done
}

case "${1:-}" in
    open-keybox)
        am start -a android.intent.action.VIEW -d 'https://keybox.kowx712.cc' >/dev/null || { echo 'browser_fail' >&2; exit 1; }
        ;;
    targets)
        if [ -f "$config/target.txt" ]; then cat "$config/target.txt"; fi
        ;;
    save)
        tmp=$(mktemp "$config/.target-XXXXXX") || exit 1
        trap 'rm -f "$tmp"' EXIT HUP INT TERM
        decode "${2:-}" > "$tmp" || exit 1
        if grep -Ev '^[[:alnum:]_][[:alnum:]_.]*[!?]?$|^[[:space:]]*$|^[[:space:]]*#' "$tmp" | grep -q .; then
            echo 'bad_list' >&2
            exit 1
        fi
        chmod 600 "$tmp"
        if [ -f "$config/target.txt" ]; then
            cp -p "$config/target.txt" "$config/target.txt.bak" || exit 1
        fi
        mv -f "$tmp" "$config/target.txt" || exit 1
        trap - EXIT HUP INT TERM
        refresh_attestation
        echo 'ok'
        ;;
    downloaded-keyboxes)
        for file in "$downloads"/*; do
            [ -f "$file" ] && [ ! -L "$file" ] || continue
            case "${file##*/}" in
                *.xml|*.XML) printf '%s' "${file##*/}" | base64 | tr -d '\n'; printf '\n';;
            esac
        done
        ;;
    set-keybox|set-downloaded-keybox)
        tmp=$(mktemp "$config/.keybox-XXXXXX") || exit 1
        trap 'rm -f "$tmp"' EXIT HUP INT TERM
        if [ "$1" = set-keybox ]; then
            decode "${2:-}" > "$tmp" || exit 1
        else
            name=$(decode "${2:-}") || exit 1
            case "$name" in
                *.xml|*.XML) case "$name" in */*) echo 'kb_name_bad' >&2; exit 1;; esac;;
                *) echo 'kb_not_xml' >&2; exit 1;;
            esac
            [ -f "$downloads/$name" ] && [ ! -L "$downloads/$name" ] || { echo 'kb_not_found' >&2; exit 1; }
            [ "$(wc -c < "$downloads/$name")" -le 65536 ] || { echo 'kb_too_big' >&2; exit 1; }
            cp "$downloads/$name" "$tmp" || exit 1
        fi
        [ -s "$tmp" ] && [ "$(wc -c < "$tmp")" -le 65536 ] || { echo 'kb_bad_size' >&2; exit 1; }
        for tag in AndroidAttestation Keybox PrivateKey CertificateChain Certificate; do
            grep -q "<$tag[ >]" "$tmp" && grep -q "</$tag>" "$tmp" || { echo 'kb_missing_tags' >&2; exit 1; }
        done
        if grep -iEq '<!DOCTYPE|<!ENTITY' "$tmp"; then
            echo 'kb_dtd' >&2
            exit 1
        fi
        chmod 600 "$tmp"
        if [ -f "$config/keybox.xml" ]; then
            cp -p "$config/keybox.xml" "$config/keybox.xml.bak" || exit 1
        fi
        mv -f "$tmp" "$config/keybox.xml" || exit 1
        trap - EXIT HUP INT TERM
        refresh_attestation
        echo 'ok'
        ;;
    patch)
        command -v curl >/dev/null 2>&1 || { echo 'no_curl' >&2; exit 1; }
        tmp=$(mktemp "$config/.bulletin-XXXXXX") || exit 1
        trap 'rm -f "$tmp"' EXIT HUP INT TERM
        curl -fLsS --connect-timeout 10 --max-time 25 'https://source.android.com/docs/security/bulletin/pixel' > "$tmp" || { echo 'bulletin_fail' >&2; exit 1; }
        patch=$(grep -oE '<td>20[0-9]{2}-(0[1-9]|1[0-2])-0[15]</td>' "$tmp" | sed 's/<[^>]*>//g' | sort -r | head -n 1) || true
        [ -n "$patch" ] || { echo 'patch_fetch_fail' >&2; exit 1; }
        printf '%s\n' "$patch"
        ;;
    set-patch)
        patch=${2:-}
        printf '%s\n' "$patch" | grep -Eq '^20[0-9]{2}-(0[1-9]|1[0-2])-0[15]$' || { echo 'patch_bad' >&2; exit 1; }
        # system patch must stay the REAL firmware value: GMS reads the real patch via
        # libgmsspoof, so the forged attestation's osPatchLevel must match it or Play
        # Integrity drops below STRONG. only boot/vendor follow the chosen recent date.
        real=$(sed -n 's/^ro\.build\.version\.security_patch=//p' /system/build.prop /system/system/build.prop 2>/dev/null | head -n 1)
        case "$real" in 20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]) ;; *) real=$patch ;; esac
        tmp=$(mktemp "$config/.patch-XXXXXX") || exit 1
        trap 'rm -f "$tmp"' EXIT HUP INT TERM
        printf 'system=%s\nboot=%s\nvendor=%s\n' "$real" "$patch" "$patch" > "$tmp"
        chmod 600 "$tmp"
        if [ -f "$config/security_patch.txt" ]; then
            cp -p "$config/security_patch.txt" "$config/security_patch.txt.bak" || exit 1
        fi
        mv -f "$tmp" "$config/security_patch.txt" || exit 1
        trap - EXIT HUP INT TERM
        refresh_attestation
        echo 'ok'
        ;;
    *) echo 'bad_action' >&2; exit 1;;
esac
