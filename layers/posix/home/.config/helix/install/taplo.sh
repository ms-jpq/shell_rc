#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${BIN?}"
: "${RUN?}"

BASE='https://github.com/tamasfe/taplo/releases/latest/download/taplo'

EXT=''
case "$OSTYPE" in
darwin*)
  URI="$BASE-darwin-$HOSTTYPE.gz"
  ;;
linux*)
  URI="$BASE-linux-$HOSTTYPE.gz"
  ;;
*)
  URI="$BASE-windows-$HOSTTYPE.zip"
  EXT='.exe'
  ;;
esac

get.sh "$URI" | unpack.sh "$RUN"
F=("$RUN"/*)
chmod +x "${F[@]}"
install -v -bD -- "${F[@]}" "$BIN/taplo$EXT"
