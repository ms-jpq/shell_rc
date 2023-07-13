#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

FONTS=("$(figlet -I 2)"/**.flf)

if ! [[ -v FONT ]]; then
  FONT="${FONTS[$((RANDOM % ${#FONTS[@]}))]}"
fi

if [[ -v SHOW_FONT ]]; then
  printf -- '%s' "$FONT"
  exit
fi

COLS=$(tput -- cols)

ARGS=(
  -c
  -w "$COLS"
  -f "$FONT"
)

if [[ -t 0 ]]; then
  TEXT="$*"
else
  TEXT="$(</dev/stdin)"
fi

TEXT="${TEXT:-BIGLY}"
LINES="$(figlet "${ARGS[@]}" <<<"$TEXT")"
DEL="$(tr -d '[:space:]' <<<"$LINES")"

if [[ -z "$DEL" ]]; then
  exec -- "$0" "$@"
else
  printf -- '%s\n' "$LINES"
fi