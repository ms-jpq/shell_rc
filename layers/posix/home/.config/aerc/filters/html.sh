#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

MAX=88

COLS=$((MAX))
if [[ -v AERC_MIME_TYPE ]]; then
  COLS="$(stty size < /dev/tty | cut -d ' ' -f 2)"
fi

if ((COLS > MAX)); then
  COLS=$((MAX))
fi

ARGV=(
  w3m -W
  -T text/html
  -s
  -cols "$COLS"
  -o display_link_number=1
  -o tabstop=2
)

SED=(
  sed -E
  -e $'s/[\u2007\u200b\u034f\u200c\u202b]/ /g'
  -e '/[[:space:]]+$/d'
)

"${ARGV[@]}" "$@" | if [[ -v AERC_MIME_TYPE ]]; then
  SELF="$(realpath -- "$0")"
  BASE="${SELF%/*}"
  tac | COLS="$COLS" "$BASE/html.awk" | tac
else
  tee
fi | "${SED[@]}"
