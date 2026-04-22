#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

REPO='ltex-plus/ltex-ls-plus'
BASE="https://github.com/$REPO/releases/latest/download/ltex-ls-plus"
VERSION="$(gh-latest.sh . "$REPO")"

EXT=''
case "$OSTYPE" in
darwin*)
  URI="$BASE-$VERSION-mac-x64.tar.gz"
  ;;
linux*)
  URI="$BASE-$VERSION-linux-x64.tar.gz"
  ;;
*)
  URI="$BASE-$VERSION-windows-x64.zip"
  EXT='.cmd'
  ;;
esac

# shellcheck disable=SC2154
DST="$BIN/ltex-ls-plus$EXT"

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$RUN"
# shellcheck disable=SC2154
rm -rf -- "$LIB"
mkdir -v -p -- "$BIN" "$LIB"
mv -f -- "$RUN"/*/* "$LIB/"
ln -v -snf -- "$LIB/bin/$(basename -- "$DST")" "$DST"
