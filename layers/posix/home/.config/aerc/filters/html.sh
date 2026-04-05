#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if [[ -v AERC_MIME_TYPE ]]; then
  COLOUR=1
  COLS="$(stty size < /dev/tty | cut -d ' ' -f 2)"
else
  COLOUR=0
  COLS=168
fi

ARGV=(
  w3m -W
  -T text/html
  -graph
  -cols "$COLS"
  -o color="$COLOUR"
  -o display_image=1
  -o display_link_number=1
  -o ignorecase_search=1
  -o tabstop=2
)

BOLD_RED=$'\e[1;31m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[0;33m'
BOLD_YELLOW=$'\e[1;33m'
CLS=$'\e[0m'

if [[ -v AERC_MIME_TYPE ]]; then
  FILTER=(
    sed -E
    -e "s#(\[[[:digit:]]+\])[[:space:]]?#$BOLD_RED\1 $CLS#g"
    -e "s#(https?://[^ ]+)#$GREEN\1$CLS#g"
    -e "s#(mailto:[^ ]+)#$YELLOW\1$CLS#g"
    -e "s#(^|[[:space:]]+)([[:digit:]]{6,})([[:space:]]+|$)#$BOLD_YELLOW\2$CLS#g"
  )
else
  FILTER=(cat --)
fi

SED=(
  sed -E
  -e $'s/\u2007/ /g'
  -e $'s/\u034f/ /g'
  -e $'s/\u200c/ /g'
  -e $'s/\u202b/ /g'
  -e '/[[:space:]]+$/d'
)

"${ARGV[@]}" "$@" | "${FILTER[@]}" | "${SED[@]}"
