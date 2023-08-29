#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

A0="$1"
ARGV=("$A0")
shift -- 1

read -r -d '' -- SCRIPT

case "$A0" in
m4)
  ARGV+=(--prefix-builtins)
  ;;
psql)
  ARGV+=(--no-password --single-transaction --expanded)
  ;;
*) ;;
esac

"${ARGV[@]}" "$@" <<<"$SCRIPT" || true
exec -- "$0" "$A0" "$@"
