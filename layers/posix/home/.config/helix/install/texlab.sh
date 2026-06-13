#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# shellcheck disable=SC2154
T_BIN="$BIN/tectonic"

BASE='https://github.com/latex-lsp/texlab/releases/latest/download/texlab'
T_REPO='tectonic-typesetting/tectonic'
T_BASE="https://github.com/$T_REPO/releases/latest/download"
T_VERSION="$(gh-latest.sh . "$T_REPO")"
T_VERSION="${T_VERSION/'@'/'-'}"

EXT=''
case "$OSTYPE" in
darwin*)
  URI="$BASE-$HOSTTYPE-macos.tar.gz"
  T_URI="$T_BASE/$T_VERSION-$HOSTTYPE-apple-darwin.tar.gz"
  ;;
linux*)
  URI="$BASE-$HOSTTYPE-linux.tar.gz"
  T_URI="$T_BASE/$T_VERSION-$HOSTTYPE-unknown-linux-gnu.tar.gz"
  ;;
*)
  URI="$BASE-$HOSTTYPE-windows.zip"
  T_URI="$T_BASE/$T_VERSION-$HOSTTYPE-pc-windows-msvc.zip"
  EXT='.exe'
  T_BIN="$T_BIN.exe"
  ;;
esac

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$RUN"
get.sh "$T_URI" | unpack.sh "$RUN"
# shellcheck disable=SC2154
install -v -bD -- "$RUN/texlab"* "$BIN/texlab$EXT"
install -v -bD -- "$RUN/tectonic"* "$T_BIN"
