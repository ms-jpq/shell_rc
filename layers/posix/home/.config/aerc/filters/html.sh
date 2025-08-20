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

exec -- "${ARGV[@]}" "$@"
