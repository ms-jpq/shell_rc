#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${BIN?}"
: "${RUN?}"

BASE='https://github.com/vale-cli/vale-ls/releases/latest/download/vale-ls'
V_REPO='vale-cli/vale'
V_BASE="https://github.com/$V_REPO/releases/latest/download/vale"
V_VERSION="$(gh-latest.sh . "$V_REPO")"
V_VERSION="${V_VERSION#v}"

case "$HOSTTYPE" in
aarch64)
  V_ARCH='arm64'
  ;;
x86_64)
  V_ARCH='64-bit'
  ;;
*)
  set -x
  exit 2
  ;;
esac

EXT=''
case "$OSTYPE" in
darwin*)
  URI="$BASE-$HOSTTYPE-apple-darwin.zip"
  V_URI="${V_BASE}_${V_VERSION}_macOS_$V_ARCH.tar.gz"
  ;;
linux*)
  URI="$BASE-$HOSTTYPE-unknown-linux-gnu.zip"
  V_URI="${V_BASE}_${V_VERSION}_Linux_$V_ARCH.tar.gz"
  ;;
msys | cygwin)
  EXT='.exe'
  V_URI="${V_BASE}_${V_VERSION}_Windows_$V_ARCH.zip"
  case "$HOSTTYPE" in
  x86_64)
    URI="$BASE-$HOSTTYPE-pc-windows-gnu.zip"
    ;;
  aarch64)
    URI="$BASE-$HOSTTYPE-pc-windows-msvc.zip"
    ;;
  *)
    set -x
    exit 2
    ;;
  esac
  ;;
*)
  set -x
  exit 2
  ;;
esac

get.sh "$URI" | unpack.sh "$RUN"
get.sh "$V_URI" | unpack.sh "$RUN"
install -v -bD -- "$RUN/"**"/vale-ls$EXT" "$BIN/vale-ls$EXT"
install -v -bD -- "$RUN/vale$EXT" "$BIN/vale$EXT"
