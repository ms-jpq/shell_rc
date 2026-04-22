#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

ROOT="${1-$HOME/Library/Caches}"

for ENTRY in "$ROOT"/*/; do
  ENTRY="${ENTRY%/}"
  if [[ -r $ENTRY && -w $ENTRY ]]; then
    printf -- '%s\n' "${ENTRY##*/}"
  fi
done
