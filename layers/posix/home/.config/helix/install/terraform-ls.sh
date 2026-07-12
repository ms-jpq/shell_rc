#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

BASE_URI='https://releases.hashicorp.com/terraform-ls'
VERSION="$(gh-latest.sh . 'hashicorp/terraform-ls')"
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

URI="$BASE_URI/$VERSION/terraform-ls_${VERSION}_$NAME.zip"

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$RUN"
# shellcheck disable=SC2154
install -v -bD -t "$BIN" -- "$RUN/terraform"*
