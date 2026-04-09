#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if [[ -v AERC_MIME_TYPE ]]; then
  MAX=128

  C="$(stty size < /dev/tty | cut -d ' ' -f 2)"
  COLS="$C"
  if ((COLS > MAX)); then
    COLS=$((MAX))
  fi
else
  COLS=88
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
  tac | IDENT=$(((C - COLS) / 2)) WIDTH="$C" "$BASE/html.awk" | tac
else
  tee
fi | "${SED[@]}"
