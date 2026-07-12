#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

REPO='mvdan/sh'
BASE="https://github.com/$REPO/releases/latest/download/shfmt"
VERSION="$(gh-latest.sh . "$REPO")"

case "$HOSTTYPE" in
aarch64)
  HT='arm64'
  ;;
*)
  HT='amd64'
  ;;
esac

NAME=shfmt
case "$OSTYPE" in
darwin*)
  URI="${BASE}_${VERSION}_darwin_$HT"
  ;;
linux*)
  URI="${BASE}_${VERSION}_linux_$HT"
  ;;
*)
  URI="${BASE}_${VERSION}_windows_$HT.exe"
  NAME="$NAME.exe"
  ;;
esac

FILE="$(get.sh "$URI")"
# shellcheck disable=SC2154
install -v -bD -- "$FILE" "$BIN/$NAME"
