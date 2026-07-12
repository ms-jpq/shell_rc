#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

MAX=128

C="$COLUMNS"
if ((C > MAX)); then
  C=$((MAX))
fi

TEXT="$(tee)"
MAX_LINE_LEN="$(wc --max-line-length <<< "$TEXT")"

colorize <<< "$TEXT" | if ((MAX_LINE_LEN > (COLUMNS / 2))); then
  tee
else
  pr --omit-header --omit-pagination --indent $((C / 2)) --width $((C))
fi
