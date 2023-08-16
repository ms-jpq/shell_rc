#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

GPT_TMP="$1"

if [[ -t 1 ]]; then
  PAGER='glow'
else
  PAGER='cat'
fi
CURL=(
  "${0%%-*}"
  --write-out '%{http_code}'
  --output "$GPT_TMP"
  --data @-
  -- 'https://api.openai.com/v1/chat/completions'
)

"${0%/*}/../libexec/hr.sh" '?'
CODE="$(RECURSION=1 "${CURL[@]}")"

if ((CODE != 200)); then
  jq <"$GPT_TMP" || cat -- "$GPT_TMP"
else
  jq --exit-status --raw-output '.choices[].message.content' <"$GPT_TMP" | "$PAGER"
fi
