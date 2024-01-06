#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

CONSERVE=3

if ! [[ -v RELEASE ]]; then
  TIME="$(date -- '+%y %m')"
  YEAR="${TIME%% *}"
  MONTH="${TIME##* }"
  MONTH="${MONTH#0}"

  if ! ((YEAR % 2)) && ((MONTH < (4 + CONSERVE))); then
    YEAR=$((YEAR - 1))
  fi

  RELEASE="$((YEAR / 2 * 2)).04"
fi

printf -- '%s' "$RELEASE"
