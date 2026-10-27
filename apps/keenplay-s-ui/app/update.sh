#!/opt/bin/bash
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/common.sh"
require_installation

command -v curl >/dev/null 2>&1 || fail 'curl is required.'
command -v jq >/dev/null 2>&1 || fail 'jq is required to verify the official GitHub release.'
command -v sha256sum >/dev/null 2>&1 || fail 'sha256sum is required to verify the official GitHub release.'
command -v tar >/dev/null 2>&1 || fail 'tar is required.'

work=$(mktemp -d "$OPT_ROOT/tmp/playkeen-sui.XXXXXX")
old_version=$($SUI_BIN -v | awk '/S-UI Panel/{print $NF; exit}')
[ -n "$old_version" ] || fail 'unable to detect the installed S-UI version.'
backup_dir="$SUI_ROOT/cache/playkeen-adapter"
mkdir -p "$backup_dir"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tag=$(tr -d '\r\n' < "$script_dir/../UPSTREAM_VERSION")
case "$tag" in v[0-9]*) ;; *) fail 'adapter release has an invalid pinned S-UI version.' ;; esac
service_was_running=0
stopped=0
swapped=0
backup=""
cleanup() {
    result=$?
    trap - EXIT HUP INT TERM
    if [ "$result" -ne 0 ]; then
        if [ "$swapped" -eq 1 ] && [ -n "$backup" ]; then cp -p "$backup" "$SUI_BIN"; fi
        if [ "$service_was_running" -eq 1 ] && [ "$stopped" -eq 1 ]; then "$SERVICE" start playkeen-adapter >/dev/null 2>&1 || true; fi
    fi
    rm -rf "$work"
    exit "$result"
}
trap cleanup EXIT HUP INT TERM

curl -fsSL "https://api.github.com/repos/alireza0/s-ui/releases/tags/$tag" -o "$work/release.json"
release_tag=$(jq -er '.tag_name' "$work/release.json")
[ "$release_tag" = "$tag" ] || fail 'official GitHub release tag does not match the adapter release.'
asset=$(jq -cer '.assets[] | select(.name == "s-ui-linux-arm64.tar.gz")' "$work/release.json") || fail 'official release has no arm64 archive.'
url=$(printf '%s' "$asset" | jq -er '.browser_download_url')
digest=$(printf '%s' "$asset" | jq -er '.digest | select(startswith("sha256:")) | sub("^sha256:"; "")')
[ "${url#https://github.com/alireza0/s-ui/releases/download/}" != "$url" ] || fail 'release asset URL is outside the official S-UI repository.'

if [ "$old_version" = "${tag#v}" ]; then
    printf 'S-UI %s is already current.\n' "$old_version"
    exit 0
fi

curl -fL --retry 2 "$url" -o "$work/s-ui.tar.gz"
actual=$(sha256sum "$work/s-ui.tar.gz" | awk '{print $1}')
[ "$actual" = "$digest" ] || fail 'official release SHA-256 verification failed.'
tar -tzf "$work/s-ui.tar.gz" >/dev/null || fail 'official release archive is invalid.'
mkdir "$work/extracted"
tar -xzf "$work/s-ui.tar.gz" -C "$work/extracted"
new_bin=$(find "$work/extracted" -type f -name sui -print | head -n 1)
[ -n "$new_bin" ] || fail 'official release archive does not contain the S-UI executable.'
chmod 755 "$new_bin"
new_version=$("$new_bin" -v 2>&1 | awk '/S-UI Panel/{print $NF; exit}')
[ "$new_version" = "${tag#v}" ] || fail "downloaded S-UI version '$new_version' does not match '$tag'."

backup="$backup_dir/sui.$old_version"
cp -p "$SUI_BIN" "$backup"
if "$SERVICE" status >/dev/null 2>&1; then service_was_running=1; fi
if [ "$service_was_running" -eq 1 ]; then "$SERVICE" stop playkeen-adapter; stopped=1; fi
cp "$new_bin" "$SUI_BIN.playkeen-new"
chmod 755 "$SUI_BIN.playkeen-new"
mv -f "$SUI_BIN.playkeen-new" "$SUI_BIN"
swapped=1

if [ "$service_was_running" -eq 1 ]; then
    "$SERVICE" start playkeen-adapter
    sleep 1
    "$SERVICE" status >/dev/null 2>&1 || fail "S-UI $tag failed to start; restoring version $old_version."
fi
printf '%s\n' "$backup" > "$backup_dir/last-update-backup"
swapped=0
printf 'Updated S-UI core to %s; database, certificates and configuration were preserved. Previous binary: %s\n' "$tag" "$backup"
