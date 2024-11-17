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

COLS="$(tput -- cols)"
COLS=$((COLS - 4))
PAGE=(glow --config /dev/null --style pink --width "$COLS")

read -r -d '' -- JQ <<- 'JQ' || true
.results[] | "# # \(.title | gsub("\\s+"; " ") | @html)\n## [➜](\(.url | @html))\n\(.content | @html)"
JQ
J=(jq --unbuffered --raw-output "$JQ")

for N in {1..3}; do
  {
    "${CURL[@]}" -- "$URI/search?format=json&pageno=$N&q=$QUERY" | "${J[@]}"
    printf -- '\n---\n'
  } | CLICOLOR_FORCE=1 COLORTERM=truecolor "${PAGE[@]}"
done | less
