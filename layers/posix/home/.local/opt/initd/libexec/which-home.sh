#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
msys*)
  printf -v HOMIE -- '%s' ~
  DRIVELESS="${HOMIE#*:}"
  DRIVE="${HOMIE%%:*}"
  DRIVE="${DRIVE,,}"
  NORM="/$DRIVE$DRIVELESS"
  NORM="${NORM//'\'/'/'}"
  printf -- '%s' "$NORM"
  ;;
*)
  printf -- '%s' ~
  ;;
esac
