#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

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

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$RUN"
F=("$RUN"/*)
chmod +x "${F[@]}"
# shellcheck disable=SC2154
mkdir -p -- "$BIN"
install -v -b -- "${F[@]}" "$BIN/taplo$EXT"
