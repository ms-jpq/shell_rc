#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

A0='ping'
ARGV=()

for A in "$@"; do
  case "$A" in
  -4)
    A0=ping
    ;;
  -6)
    A0=ping6
    ;;
  *:*)
    A0=ping6
    ARGV+=("$A")
    ;;
  *)
    ARGV+=("$A")
    ;;
  esac
done

exec -- "$A0" "${ARGV[@]}"
