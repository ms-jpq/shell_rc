#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

COLS="$(stty size < /dev/tty | cut -d ' ' -f 2)"

ARGV=(
  w3m -W
  -T text/html
  -graph
  -cols "$COLS"
  -o color=1
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

SED=(
  sed -E
  -e "s#(\[[[:digit:]]+\])#$BOLD_RED\1$CLS#g"
  -e "s#(https?://[^ ]+)#$GREEN\1$CLS#g"
  -e "s#(mailto:[^ ]+)#$YELLOW\1$CLS#g"
  -e "s#[^[]([[:digit:]]{6,})[^]]?#$BOLD_YELLOW\1$CLS#g"
)

"${ARGV[@]}" "$@" | "${SED[@]}"
