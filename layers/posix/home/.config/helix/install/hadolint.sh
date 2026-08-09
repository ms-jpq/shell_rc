#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${BIN?}"

BASE='https://github.com/hadolint/hadolint/releases/latest/download/hadolint'

case "$HOSTTYPE" in
aarch64)
  HT='arm64'
  ;;
*)
  HT="$HOSTTYPE"
  ;;
esac

EXT=''
case "$OSTYPE" in
darwin*)
  URI="$BASE-macos-$HT"
  ;;
linux*)
  URI="$BASE-Linux-$HT"
  ;;
*)
  URI="$BASE-Windows-$HT.exe"
  EXT='.exe'
  ;;
esac

FILE="$(get.sh "$URI")"
install -v -bD -- "$FILE" "$BIN/hadolint$EXT"
