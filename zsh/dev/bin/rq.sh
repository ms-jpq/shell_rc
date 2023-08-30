#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

A0="$1"
shift -- 1

read -r -d '' -- SCRIPT

printf -- '\n>> '
printf -- '%q ' "$A0" "$@"
"$A0" "$SCRIPT" "$@" || true
exec -- "$0" "$A0" "$@"
