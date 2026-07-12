#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

MAX=128

C="$COLUMNS"
if ((C > MAX)); then
  C=$((MAX))
fi

PANDOC=(
  pandoc
  --reference-links
  --reference-location block
  --eol lf
  --read html-native_divs-native_spans
  --write markdown
  --lua-filter "${0%/*}/../libexec/html-filter.lua"
  --columns $((C - 4))
)

"${PANDOC[@]}" | sed -E -e 's#(data:image/[^;]+;).*$#\1#g'
