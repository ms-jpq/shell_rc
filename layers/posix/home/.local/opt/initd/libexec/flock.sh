#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LOCK="$1"
shift -- 1

if command -v -- flock > /dev/null; then
  exec -- flock "$LOCK" "$@"
else
  exec -- "$@"
fi
