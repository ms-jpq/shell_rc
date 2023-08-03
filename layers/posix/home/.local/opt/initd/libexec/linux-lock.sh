#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# TODO: remove this on ubuntu 24.04, when .WAIT is supported
if ! [[ -v LOCKED ]] && command -v -- flock >/dev/null; then
  ARG0="$1"
  LOCKED=1 exec -- flock "$ARG0" "$0" "$@"
else
  exec -- "$@"
fi
