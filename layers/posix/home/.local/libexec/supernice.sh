#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

IO=()
OOM=()
case "$OSTYPE" in
darwin*)
  IO=(taskpolicy -d throttle --)
  ;;
linux*)
  IO=(ionice --class idle --)
  OOM=(choom --adjust 1000 --)
  ;;
msys | cygwin) ;;
*)
  set -x
  exit 2
  ;;
esac

exec -- nice -n 19 -- "${IO[@]}" "${OOM[@]}" "$@"
