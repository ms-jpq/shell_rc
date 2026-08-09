#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${BIN?}"
: "${RUN?}"

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

get.sh "$URI" | unpack.sh "$RUN"
install -v -bD -- "$RUN/bin/glsl_analyzer$EXT" "$BIN/glsl_analyzer$EXT"
