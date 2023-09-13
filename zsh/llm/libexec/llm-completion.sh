#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

GPT_TMP="$1"
PAGER="${2:-""}"

if [[ -z "$PAGER" ]]; then
  if [[ -t 1 ]]; then
    PAGER='glow'
    printf -v PAGER -- '%q ' glow --style light
  else
    PAGER='cat'
  fi
fi

CURL=(
  "${0%/*}/../bin/llm"
  --write-out '%{http_code}'
  --output "$GPT_TMP"
  --data @-
  -- 'https://api.openai.com/v1/chat/completions'
)

"${0%/*}/../libexec/hr.sh" '?' >&2
CODE="$(RECURSION=1 "${CURL[@]}")"

if ((CODE != 200)); then
  jq <"$GPT_TMP" || cat -- "$GPT_TMP"
else
  jq --exit-status --raw-output '.choices[].message.content' <"$GPT_TMP" | $PAGER
fi
