#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${BIN?}"
: "${RUN?}"

BASE='https://github.com/kristoff-it/superhtml/releases/latest/download'

EXT=''
case "$OSTYPE" in
darwin*)
  URI="$BASE/$HOSTTYPE-macos.zip"
  ;;
linux*)
  case "$HOSTTYPE" in
  x86_64)
    LIBC='-musl'
    ;;
  *)
    LIBC=''
    ;;
  esac
  URI="$BASE/$HOSTTYPE-linux$LIBC.tar.xz"
  ;;
*)
  URI="$BASE/$HOSTTYPE-windows.zip"
  EXT='.exe'
  ;;
esac

ARCHIVE="superhtml-${URI##*/}"
get.sh "$URI" "$ARCHIVE" | unpack.sh "$RUN"
find "$RUN" -name '*.pdb' -delete
install -v -bD -- "$RUN"/superhtml* "$BIN/superhtml$EXT"
