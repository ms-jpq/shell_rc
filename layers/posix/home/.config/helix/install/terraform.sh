#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

: "${BIN?}"
: "${RUN?}"

BASE_URI='https://releases.hashicorp.com/terraform'
VERSION="$(gh-latest.sh . 'hashicorp/terraform')"
VERSION="${VERSION#v}"

case "$HOSTTYPE" in
aarch64)
  HT='arm64'
  ;;
*)
  HT='amd64'
  ;;
esac

case "$OSTYPE" in
darwin*)
  NAME="darwin_$HT"
  ;;
linux*)
  NAME="linux_$HT"
  ;;
*)
  NAME="windows_$HT"
  ;;
esac

URI="$BASE_URI/$VERSION/terraform_${VERSION}_$NAME.zip"

get.sh "$URI" | unpack.sh "$RUN"
install -v -bD -t "$BIN" -- "$RUN/"*
