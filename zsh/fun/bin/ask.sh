#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

F="$HOME/.local/state/searx"
if ! [[ -f $F ]]; then
  # shellcheck disable=SC2154
  "$EDITOR" "$F"
fi
URI="$(< "$F")"
QUERY="$(jq --raw-input --raw-output '@uri' <<< "$*")"
CURL=(
  curl
  --fail-with-body
  --connect-timeout 6
  --no-progress-meter
  --no-buffer
)

if [[ -t 1 ]]; then
  PAGE=(glow)
else
  PAGE=(mdcat)
fi

read -r -d '' -- JQ <<- 'JQ' || true
.results[] | "# \(.title | @html)\n## [\(if $pager == "glow" then "➜" else .url | @html end)](\(.url | @html))\n\(.content | @html)"
JQ

for N in {1..1}; do
  "${CURL[@]}" -- "$URI/search?format=json&pageno=$N&q=$QUERY"
done | jq --unbuffered --raw-output --arg pager "${PAGE[*]}" "$JQ" | "${PAGE[@]}"
