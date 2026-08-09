#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${BIN?}"
: "${RUN?}"

REPO='koalaman/shellcheck'
BASE="https://github.com/$REPO/releases/latest/download/shellcheck"
VERSION="$(gh-latest.sh . "$REPO")"

case "$OSTYPE" in
darwin*)
  URI="$BASE-$VERSION.darwin.x86_64.tar.xz"
  ;;
linux*)
  URI="$BASE-$VERSION.linux.$HOSTTYPE.tar.xz"
  ;;
*)
  exit 0
  ;;
esac

get.sh "$URI" | unpack.sh "$RUN"
install -v -bD -- "$RUN/shellcheck"*'/shellcheck' "$BIN/shellcheck"
