#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
set -x

case "$OSTYPE" in
msys)
  exec -- "${0%/*}/flock.ps1" "$@"
  ;;
*)
  LOCK="$1"
  shift -- 1
  if command -v -- flock >/dev/null; then
    exec -- flock "$LOCK" "$@"
  else
    exec -- "$@"
  fi
  ;;
esac
