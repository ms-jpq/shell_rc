#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! [[ -v LOCKED ]] && command -v -- flock >/dev/null; then
  LOCKED=1 exec -- flock "$0" "$0" "$@"
else
  exec -- "$@"
fi
