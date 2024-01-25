#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

GPT_TMP="$1"
TEE="${2:-"/dev/null"}"

CURL=(
  "${0%/*}/../bin/llm"
  --write-out '%{http_code}'
  --output "$GPT_TMP"
  --data @-
  -- 'https://api.openai.com/v1/chat/completions'
)

hr() {
  {
    printf -- '\n'
    "${0%/*}/../libexec/hr.sh" "$@"
    printf -- '\n'
  } >&2
}

hr '?'
CODE="$(RECURSION=1 "${CURL[@]}")"

if ((CODE != 200)); then
  jq <"$GPT_TMP" || cat -- "$GPT_TMP"
else
  jq --exit-status --raw-output '.choices[].message.content' <"$GPT_TMP" | tee -- "$TEE" | glow
fi
printf -- '\n' >&2
hr '^'
