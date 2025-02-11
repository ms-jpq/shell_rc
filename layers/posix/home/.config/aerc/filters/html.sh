#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

COLS="$(stty size < /dev/tty | cut -d ' ' -f 2)"

PANDOC=(
  pandoc
  --reference-links
  --reference-location block
  --eol lf
  --read html-native_divs-native_spans
  --write markdown
  --lua-filter "${0%/*}/../libexec/html-filter.lua"
  --columns $((COLS - 2))
)

"${PANDOC[@]}" | sed -E -e 's#(data:image/[^;]+;).*$#\1#g'
