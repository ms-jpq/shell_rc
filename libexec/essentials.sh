#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! hash -- gmake curl jq; then
  case "$OSTYPE" in
  darwin*)
    brew install -- make jq
    ;;
  linux*)
    sudo -- apt-get update
    DEBIAN_FRONTEND=noninteractive sudo --preserve-env -- apt-get install --no-install-recommends --yes -- make curl jq
    ;;
  msys*)
    WINGET=(
      winget install
      --disable-interactivity
      --accept-source-agreements --accept-package-agreements
      --exact
      --id
    )
    "${WINGET[@]}" GnuWin32.Make jqlang.jq
    ;;
  *)
    exit 1
    ;;
  esac
fi
