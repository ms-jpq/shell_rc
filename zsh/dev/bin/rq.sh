#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

A0="$1"
ARGV=("$A0")
shift -- 1

case "$A0" in
*) ;;
esac

read -r -d '' -- SCRIPT
printf -- '\n>> '
printf -- '%q ' "${ARGV[@]}" "$@"
printf -- '\n'
"${ARGV[@]}" "$SCRIPT" "$@" || true
exec -- "$0" "$A0" "$@"
