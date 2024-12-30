#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# shellcheck disable=SC2154
ARGV=(
  kitty @
  kitten notify
  --icon info
  --
  "📩 $AERC_FROM_NAME" "$AERC_SUBJECT"
)

exec -- "${ARGV[@]}"
