#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${BIN?}"
: "${LIB?}"
: "${RUN?}"

REPO='ltex-plus/ltex-ls-plus'
BASE="https://github.com/$REPO/releases/latest/download/ltex-ls-plus"
VERSION="$(gh-latest.sh . "$REPO")"

EXT=''
case "$HOSTTYPE" in
aarch64)
  HT='aarch64'
  ;;
*)
  HT='x64'
  ;;
esac

case "$OSTYPE" in
darwin*)
  URI="$BASE-$VERSION-mac-$HT.tar.gz"
  ;;
linux*)
  URI="$BASE-$VERSION-linux-$HT.tar.gz"
  ;;
*)
  URI="$BASE-$VERSION-windows-x64.zip"
  EXT='.cmd'
  ;;
esac

DST="$BIN/ltex-ls-plus$EXT"

get.sh "$URI" | unpack.sh "$RUN"
rm -rf -- "$LIB"
mkdir -v -p -- "$BIN" "$LIB"
mv -f -- "$RUN"/*/* "$LIB/"
ln -v -sTnfr -- "$LIB/bin/$(basename -- "$DST")" "$DST"
