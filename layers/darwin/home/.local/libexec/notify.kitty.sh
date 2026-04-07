#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SOCK="$1"
ID="$2"
TITLE="$3"
MESSAGE="$4"
shift -- 4

ARGV=(
  /Applications/kitty.app/Contents/MacOS/kitten @
  --to "unix:$SOCK"
  --
  kitten notify
  --identifier "$ID"
  "$@"
  -- "$TITLE" "$MESSAGE"
)

exec -- "${ARGV[@]}"
