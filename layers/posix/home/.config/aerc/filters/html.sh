#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

COLS="$(stty size < /dev/tty | cut -d ' ' -f 2)"

ARGV=(
  w3m -W
  -T text/html
  -graph
  -cols "$COLS"
  -o display_link_number=1
)

exec -- "${ARGV[@]}" "$@"
