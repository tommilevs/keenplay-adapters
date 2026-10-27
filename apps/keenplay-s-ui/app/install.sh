#!/opt/bin/bash
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/common.sh"
require_installation

printf 'Existing S-UI installation detected; adopting without reinstalling or changing its data.\n'
"$SUI_BIN" -v
if "$SERVICE" status >/dev/null 2>&1; then
    printf 'S-UI service is running.\n'
else
    printf 'S-UI service is installed but currently stopped; migration leaves its state unchanged.\n'
fi
