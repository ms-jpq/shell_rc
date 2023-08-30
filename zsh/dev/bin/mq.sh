#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

A0="$1"
ARGV=("$A0")
shift -- 1

case "$A0" in
m4)
  ARGV+=(--prefix-builtins)
  ;;
perl)
  ARGV+=(-CASD -w)
  ;;
psql)
  ARGV+=(--no-password --single-transaction --expanded)
  ;;
node)
  ARGV+=(--input-type=module)
  ;;
jshell)
  ARGV+=(-)
  ;;
*) ;;
esac

ARGV+=("$@")

read -r -d '' -- SCRIPT
printf -- '\n>> '
printf -- '%q ' "${ARGV[@]}"
"${ARGV[@]}" <<<"$SCRIPT" || true
exec -- "$0" "$A0" "$@"
