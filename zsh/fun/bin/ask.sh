#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if [[ -v XDG_OPEN ]]; then
  TMP="$1"
  N="$2"
  URI="$(jq --raw-output --argjson n "$N" '.results[$n].url' "$TMP")"
  if command -v -- xdg-open; then
    xdg-open "$URI"
  else
    open -- "$URI"
  fi
elif ! [[ -v FZF_PREVIEW_LINES ]]; then
  F="$HOME/.local/state/searx"
  if ! [[ -f $F ]]; then
    # shellcheck disable=SC2154
    "$EDITOR" "$F"
  fi
  DOMAIN="$(< "$F")"
  QUERY="$(jq --raw-input --raw-output '@uri' <<< "$*")"
  TMP="$(mktemp)"
  HEADERS=(
  )
  CURL=(
    curl
    --fail-with-body
    --connect-timeout 6
    --no-progress-meter
  )
  for HEADER in "${HEADERS[@]}"; do
    CURL+=(--header "$HEADER")
  done
  CURL+=(-- "https://$DOMAIN/search?format=json&q=$QUERY")
  "${CURL[@]}" > "$TMP"
  PREVIEW="$(printf -- '%q ' "$0" "$TMP")"
  EXEC="$(printf -- '%q ' 'XDG_OPEN=1' "$0" "$TMP")"
  FZF=(
    fzf
    --read0
    --preview "$PREVIEW {n}"
    --bind "enter:execute-silent:$EXEC {n}"
  )
  jq --raw-output0 '.results | map(.title)[]' "$TMP" | "${FZF[@]}"
else
  TMP="$1"
  N="$2"
  read -r -d '' -- JQ <<- 'JQ' || true
.results[$n] | "<h1>\(.title | @html)</h1><h2>\(.url | @html)</h2>\("<p>\(.content | @html)</p>")"
JQ
  # shellcheck disable=2154
  jq --raw-output --argjson n "$N" "$JQ" "$TMP" | pandoc --from html --to gfm | glow --style light --width "$FZF_PREVIEW_COLUMNS"
fi
