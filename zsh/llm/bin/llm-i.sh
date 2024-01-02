#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PROMPT="$*"
MODEL='dall-e-3'
JSON="$(jq --exit-status --raw-input --arg model "$MODEL" '{ prompt: ., model: $model }' <<<"$PROMPT")"
RESP="$(RECURSION=1 "${0%-*}" --data @- -- 'https://api.openai.com/v1/images/generations' <<<"$JSON")"
if jq --exit-status '.error' <<<"$RESP" >/dev/null; then
  jq <<<"$RESP" >&2
else
  US="$(jq --exit-status --raw-output '.data[].url' <<<"$RESP")"
  readarray -t -- URIS <<<"$US"

  for URI in "${URIS[@]}"; do
    printf -- '%s\n' "$URI"
    open -- "$URI" || true
  done
fi
