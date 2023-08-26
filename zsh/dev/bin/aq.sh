#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PROGRAM="$1"
shift -- 1

read -r -d '' -- SCRIPT

"$PROGRAM" "$SCRIPT" "$@" || true
exec -- "$0" "$PROGRAM" "$@"
