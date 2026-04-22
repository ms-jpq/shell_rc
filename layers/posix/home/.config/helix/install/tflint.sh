#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

BASE='https://github.com/terraform-linters/tflint/releases/latest/download/tflint'

case "$HOSTTYPE" in
aarch64)
  HT='arm64'
  ;;
*)
  HT='amd64'
  ;;
esac

EXT=''
case "$OSTYPE" in
darwin*)
  URI="${BASE}_darwin_$HT.zip"
  ;;
linux*)
  URI="${BASE}_linux_$HT.zip"
  ;;
*)
  URI="${BASE}_windows_$HT.zip"
  EXT='.exe'
  ;;
esac

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$RUN"
# shellcheck disable=SC2154
mkdir -p -- "$BIN"
install -v -b -- "$RUN/"* "$BIN/tflint$EXT"
