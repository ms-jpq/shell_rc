#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TARGET="$1"
WIDTH="$2"
_HEIGHT="$3"
_H_POS="$4"
_V_POS="$5"

BAT=(
  bat
  --force-colorization
  --wrap character
  --terminal-width $((WIDTH))
)

MIME="$(file --brief --dereference --mime-type -- "$TARGET")"
MIME="${MIME%%/*}"

if [[ $MIME == image ]]; then
  exec -- chafa -- "$TARGET"
fi

exec -- "${BAT[@]}" -- "$TARGET"
