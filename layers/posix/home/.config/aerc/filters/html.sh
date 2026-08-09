#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

COLUMNS=${COLUMNS:-"$(stty size < /dev/tty | cut -d ' ' -f 2)"}

if [[ -n ${AERC_MIME_TYPE:-} ]]; then
  MAX=128

  C="$COLUMNS"
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
  -graph
  -o auto_uncompress=0
  -o display_image=0
  -o display_link_number=1
  -o follow_redirection=0
  -o frame=0
  -o http_proxy=http://0.0.0.0:0
  -o https_proxy=http://0.0.0.0:0
  -o localhost_only=1
  -o mailcap=/dev/null
  -o meta_refresh=0
  -o no_proxy=
  -o tabstop=2
  -o urimethodmap=/dev/null
  -o use_cookie=0
  -o use_proxy=1
  -o view_unseenobject=0
)

SED=(
  sed -E
  -e $'s/[\u2007\u200b\u034f\u200c\u202b]/ /g'
  -e '/[[:space:]]+$/d'
)

"${ARGV[@]}" | if [[ -n ${AERC_MIME_TYPE:-} ]]; then
  SELF="$(realpath -- "$0")"
  BASE="${SELF%/*}"
  tac | IDENT=$(((C - COLS) / 2)) WIDTH="$C" "$BASE/html.awk" | tac
else
  tee
fi | "${SED[@]}"
