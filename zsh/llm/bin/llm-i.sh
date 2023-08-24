#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PROMPT="$*"
JSON="$(jq --exit-status --raw-input '{ prompt: . }' <<<"$PROMPT")"
RESP="$(RECURSION=1 "${0%-*}" --data @- -- 'https://api.openai.com/v1/images/generations' <<<"$JSON")"
US="$(jq --exit-status --raw-output '.data[].url' <<<"$RESP")"
readarray -t -- URIS <<<"$US"

for URI in "${URIS[@]}"; do
  printf -- '%s\n' "$URI"
  open -- "$URI" || true
done
