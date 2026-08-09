#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${BIN?}"
: "${RUN?}"

BASE='https://github.com/neocmakelsp/neocmakelsp/releases/latest/download/neocmakelsp'

EXT=''
case "$OSTYPE" in
darwin*)
  URI="$BASE-universal-apple-darwin.tar.gz"
  ;;
linux*)
  URI="$BASE-$HOSTTYPE-unknown-linux-gnu.tar.gz"
  ;;
*)
  URI="$BASE-$HOSTTYPE-pc-windows-msvc.zip"
  EXT='.exe'
  ;;
esac

get.sh "$URI" | unpack.sh "$RUN"
install -v -bD -- "$RUN"/* "$BIN/neocmakelsp$EXT"
