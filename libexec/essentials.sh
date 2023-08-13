#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
darwin*)
  if ! hash -- gmake jq; then
    brew install -- make jq
  fi
  ;;
linux*)
  if ! hash -- gmake curl jq; then
    sudo -- apt-get update
    DEBIAN_FRONTEND=noninteractive sudo --preserve-env -- apt-get install --no-install-recommends --yes -- make curl jq
  fi
  ;;
msys*)
  WINGET=(
    winget install
    --disable-interactivity
    --accept-source-agreements --accept-package-agreements
    --exact
    --id
  )
  if ! hash -- jq; then
    "${WINGET[@]}" jqlang.jq
  fi
  ;;
*)
  exit 1
  ;;
esac
