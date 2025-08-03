#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

BASE='https://github.com/nolanderc/glsl_analyzer/releases/latest/download'

EXT=''
case "$OSTYPE" in
darwin*)
  URI="$BASE/$HOSTTYPE-macos.zip"
  ;;
linux*)
  URI="$BASE/$HOSTTYPE-linux-musl.zip"
  ;;
*)
  URI="$BASE/$HOSTTYPE-windows.zip"
  EXT='.exe'
  ;;
esac
BIN="$BIN$EXT"

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$TMP"
mv -v -f -- "$TMP/bin/glsl_analyzer$EXT" "$BIN/glsl_analyzer$EXT"
