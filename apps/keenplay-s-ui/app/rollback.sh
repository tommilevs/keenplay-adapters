#!/bin/sh
set -eu
OPT_ROOT=${PLAYKEEN_OPT_ROOT:-/opt}
SUI_ROOT="$OPT_ROOT/etc/s-ui"
SUI_BIN="$SUI_ROOT/sui"
SERVICE="$OPT_ROOT/etc/init.d/S99s-ui"
backup_dir="$SUI_ROOT/cache/playkeen-adapter"
marker="$backup_dir/last-update-backup"
[ -s "$marker" ] || { echo 'No saved S-UI binary is available for rollback.' >&2; exit 1; }
backup=$(cat "$marker")
[ "$(dirname "$backup")" = "$backup_dir" ] && [ -x "$backup" ] || { echo 'Saved S-UI binary path is invalid.' >&2; exit 1; }
was_running=0
if "$SERVICE" status >/dev/null 2>&1; then was_running=1; fi
current="$backup_dir/sui.rollback-current"
cp -p "$SUI_BIN" "$current"
if [ "$was_running" -eq 1 ]; then "$SERVICE" stop playkeen-adapter; fi
cp -p "$backup" "$SUI_BIN.rollback-new"
mv -f "$SUI_BIN.rollback-new" "$SUI_BIN"
if [ "$was_running" -eq 1 ]; then
    if ! "$SERVICE" start playkeen-adapter; then
        cp -p "$current" "$SUI_BIN"
        "$SERVICE" start playkeen-adapter || true
        rm -f "$current"
        exit 1
    fi
    sleep 1
    if ! "$SERVICE" status >/dev/null 2>&1; then
        cp -p "$current" "$SUI_BIN"
        "$SERVICE" start playkeen-adapter || true
        rm -f "$current"
        echo 'Restored S-UI failed its service check; previous binary was put back.' >&2
        exit 1
    fi
fi
rm -f "$marker" "$current"
"$SUI_BIN" -v
