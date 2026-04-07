#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SOCK="$1"
TITLE="$2"
MESSAGE="$3"
shift -- 3

ARGV=(
  /Applications/kitty.app/Contents/MacOS/kitten @
  --to "unix:$SOCK"
  --
  kitten notify
  "$@"
  -- "$TITLE" "$MESSAGE"
)

exec -- "${ARGV[@]}"
