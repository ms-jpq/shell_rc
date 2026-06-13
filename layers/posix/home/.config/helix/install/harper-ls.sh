#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

BASE='https://github.com/Automattic/harper/releases/latest/download/harper-ls'

case "$OSTYPE" in
darwin*)
  URI="$BASE-$HOSTTYPE-apple-darwin.tar.gz"
  ;;
linux*)
  URI="$BASE-$HOSTTYPE-unknown-linux-gnu.tar.gz"
  ;;
*)
  URI="$BASE-$HOSTTYPE-pc-windows-msvc.zip"
  ;;
esac

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$RUN"
# shellcheck disable=2154

install -v -bD -t "$BIN" -- "$RUN/"*