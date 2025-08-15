#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TIME="$1"
shift -- 1

ARGV=()
case "$OSTYPE" in
msys)
  ARGV+=()
  ;;
*)
  if command -v -- timeout > /dev/null; then
    ARGV+=(timeout --kill-after 4 "$TIME")
  fi
  ;;
esac

exec -- "${ARGV[@]}" "$@"
