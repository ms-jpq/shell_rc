#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SIX=0
ARGV=()

for A in "$@"; do
  case "$A" in
  *:*)
    SIX=1
    ARGV+=("$A")
    ;;
  -6)
    SIX=1
    ;;
  -4)
    SIX=0
    ;;
  *)
    ARGV+=("$A")
    ;;
  esac
done

if ((SIX)); then
  ping6 "${ARGV[@]}"
else
  /sbin/ping "${ARGV[@]}"
fi
