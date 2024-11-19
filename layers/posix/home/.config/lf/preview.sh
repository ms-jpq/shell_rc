#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TARGET="$1"
WIDTH="$2"
_HEIGHT="$3"
_H_POS="$4"
_V_POS="$5"

ARGV=(
  bat
  --color always
  --wrap character
  --terminal-width $((WIDTH - 2))
)

exec -- "${ARGV[@]}" -- "$TARGET"
