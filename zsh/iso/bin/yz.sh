#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if command -v -- yazi > /dev/null; then
  exec -- yazi -- "$@"
else
  exec -- ranger -- "$@"
fi
