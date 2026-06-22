#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

TITLE="$1"
MESSAGE="$2"

if [[ -z $TITLE && -z $MESSAGE ]]; then
  exit 0
fi

SOCK=({"$TMPDIR",/tmp}/kitty.*.sock)

ARGV=(
  /opt/homebrew/bin/kitten @
  --to "${KITTY_LISTEN_ON:-unix:${SOCK[*]}}"
  --
  kitten notify
  -- "$TITLE" "$MESSAGE"
)

exec -- "${ARGV[@]}" < /dev/null
