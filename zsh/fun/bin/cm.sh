#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

COLOURS=(green red blue white yellow cyan magenta black)
COLOUR="${COLOURS[$((RANDOM % ${#COLOURS[@]}))]}"

exec -- cmatrix -ab -u 3 -C "$COLOUR" "$@"
