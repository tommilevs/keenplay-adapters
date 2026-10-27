#!/opt/bin/bash
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/common.sh"
require_installation
"$SUI_BIN" -v
"$SERVICE" status
