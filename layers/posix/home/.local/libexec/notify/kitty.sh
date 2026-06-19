#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TITLE="$1"
MESSAGE="$2"
shift -- 2

SOCK=(/tmp/kitty.*.sock)

ARGV=(
  /opt/homebrew/bin/kitten @
  --to "unix:${SOCK[*]}"
  --
  kitten notify
  "$@"
  -- "$TITLE" "$MESSAGE"
)

exec -- "${ARGV[@]}" < /dev/null
