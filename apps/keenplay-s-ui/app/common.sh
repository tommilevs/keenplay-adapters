#!/opt/bin/bash
set -eu

OPT_ROOT=${PLAYKEEN_OPT_ROOT:-/opt}
SUI_ROOT="$OPT_ROOT/etc/s-ui"
SUI_BIN="$SUI_ROOT/sui"
SUI_DB="$SUI_ROOT/db/s-ui.db"
SUI_CTL="$SUI_ROOT/s-ui.sh"
SERVICE="$OPT_ROOT/etc/init.d/S99s-ui"

fail() { printf 'S-UI adapter: %s\n' "$*" >&2; exit 1; }

require_installation() {
    [ -x "$SUI_BIN" ] || fail "S-UI core not found at $SUI_BIN; this adapter migrates an existing installation."
    [ -x "$SUI_CTL" ] || fail "S-UI service controller not found at $SUI_CTL."
    [ -s "$SUI_DB" ] || fail "S-UI database is missing or empty at $SUI_DB."
    [ -x "$SERVICE" ] || fail "S-UI init service not found at $SERVICE."
}

service_action() {
    "$SERVICE" "$1" playkeen-adapter
}

