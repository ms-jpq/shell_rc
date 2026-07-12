#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

REPO='tekumara/typos-vscode'
BASE="https://github.com/$REPO/releases/latest/download/typos-lsp"
VERSION="$(gh-latest.sh . "$REPO")"

BASE="https://github.com/$REPO/releases/download/$VERSION/typos-lsp"

EXT=''
case "$OSTYPE" in
darwin*)
  URI="$BASE-$VERSION-$HOSTTYPE-apple-darwin.tar.gz"
  ;;
linux*)
  URI="$BASE-$VERSION-$HOSTTYPE-unknown-linux-gnu.tar.gz"
  ;;
*)
  URI="$BASE-$VERSION-$HOSTTYPE-pc-windows-msvc.zip"
  EXT='.exe'
  ;;
esac

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$RUN"
# shellcheck disable=SC2154
install -v -bD -- "$RUN/"**'/typos-lsp'* "$BIN/typos-lsp$EXT"
