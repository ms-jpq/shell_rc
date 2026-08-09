#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${BIN?}"

BASE='https://github.com/artempyanykh/marksman/releases/latest/download/marksman'

EXT=''
case "$OSTYPE" in
darwin*)
  URI="$BASE-macos"
  ;;
linux*)
  URI="$BASE-linux-x64"
  ;;
*)
  EXT='.exe'
  URI="$BASE$EXT"
  ;;
esac

FILE="$(get.sh "$URI")"
install -v -bD -- "$FILE" "$BIN/marksman$EXT"
