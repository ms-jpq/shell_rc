#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! [[ -v LOCKED ]] && command -v -- flock >/dev/null; then
  LOCK="$1"
  shift -- 1
  LOCKED=1 exec -- flock "$LOCK" "$0" "$@"
else
  exec -- "$@"
fi
