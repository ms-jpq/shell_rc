#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

BASE='https://github.com/mskelton/dtsfmt/releases/latest/download/dtsfmt'

case "$OSTYPE" in
darwin*)
  URI="$BASE-$HOSTTYPE-apple-darwin.tar.gz"
  ;;
linux*)
  case "$HOSTTYPE" in
  x86_64)
    URI="$BASE-$HOSTTYPE-unknown-linux-musl.tar.gz"
    ;;
  *)
    URI="$BASE-arm-unknown-linux-gnueabihf.tar.gz"
    ;;
  esac
  ;;
*)
  exit 0
  ;;
esac

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$RUN"
# shellcheck disable=SC2154
install -v -bD -- "$RUN/dtsfmt" "$BIN/dtsfmt"
