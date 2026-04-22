#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

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
# shellcheck disable=SC2154
get.sh "$URI" "$ARCHIVE" | unpack.sh "$RUN"
find "$RUN" -name '*.pdb' -delete
# shellcheck disable=SC2154
mkdir -p -- "$BIN"
install -v -b -- "$RUN"/superhtml* "$BIN/superhtml$EXT"
