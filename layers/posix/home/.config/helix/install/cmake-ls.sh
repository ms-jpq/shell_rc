#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

BASE='https://github.com/neocmakelsp/neocmakelsp/releases/latest/download/neocmakelsp'

EXT=''
case "$OSTYPE" in
darwin*)
  URI="$BASE-$HOSTTYPE-apple-darwin"
  ;;
linux*)
  URI="$BASE-$HOSTTYPE-unknown-linux-gnu"
  ;;
*)
  URI="$BASE-$HOSTTYPE-pc-windows-msvc.exe"
  EXT='.exe'
  ;;
esac

FILE="$(get.sh "$URI")"
# shellcheck disable=SC2154
mkdir -p -- "$BIN"
install -v -b -- "$FILE" "$BIN/neocmakelsp$EXT"
