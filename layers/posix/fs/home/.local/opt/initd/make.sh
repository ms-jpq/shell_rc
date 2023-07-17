#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}"

OS_RELEASE='/etc/os-release'

if [[ -f "$OS_RELEASE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source -- "$OS_RELEASE"
  set +a
fi

make
