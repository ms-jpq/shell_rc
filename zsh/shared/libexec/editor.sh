#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

FILE="$*"

ARGS=()
if [[ -f "$FILE" ]]; then
  :
elif [[ "$FILE" =~ (.+)(:|#|@)([[:digit:]]+)$ ]]; then
  F="${BASH_REMATCH[1]}"
  if [[ -f "$F" ]]; then
    FILE="$F"
    LINE="${BASH_REMATCH[3]}"
    ARGS+=("+execute $LINE")
  fi
fi

if [[ -n "$FILE" ]]; then
  ARGS+=(-- "$FILE")
fi

exec -- nvim "${ARGS[@]}"
