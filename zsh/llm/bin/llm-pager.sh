#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}"

GPT_TMP="$1"

if [[ -t 1 ]]; then
  PAGER='glow'
else
  PAGER='cat'
fi

CODE="$(</dev/stdin)"
if ((CODE != 200)); then
  jq <"$GPT_TMP" || cat -- "$GPT_TMP"
else
  jq --exit-status --raw-output '.choices[].message.content' <"$GPT_TMP" | "$PAGER"
fi
