#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# shellcheck disable=SC2154
DST="$LIB/lsp-ai"
BASE='https://github.com/SilasMarvin/lsp-ai/releases/latest/download/lsp-ai'

EXT=''
case "$OSTYPE" in
darwin*)
  URI="$BASE-$HOSTTYPE-apple-darwin.gz"
  ;;
linux*)
  URI="$BASE-$HOSTTYPE-unknown-linux-gnu.gz"
  ;;
*)
  URI="$BASE-$HOSTTYPE-pc-windows-msvc.zip"
  EXT='.exe'
  ;;
esac

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$RUN"

rm -rf -- "$LIB"
mkdir -p -- "$LIB"

case "$OSTYPE" in
darwin* | linux*)
  SRC=("$RUN"/*)
  ;;
*)
  SRC=("$RUN/lsp-ai.exe")
  ;;
esac

mv -v -f -- "${SRC[@]}" "$DST$EXT"
chmod +x "$DST"
