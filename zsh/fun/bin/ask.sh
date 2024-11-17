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
COLS=$((COLS - 2))
# PAGE=(glow)
PAGE=(mdcat --columns "$COLS" --no-pager)

read -r -d '' -- JQ <<- 'JQ' || true
.results[] | "# \(.title | @html)\n## [\(if $pager == "glow" then "➜" else .url | @html end)](\(.url | @html))\n\(.content | @html)\n\n---\n"
JQ
J=(jq --unbuffered --raw-output --arg pager "${PAGE[*]}" "$JQ")

for N in {1..2}; do
  # shellcheck disable=SC2154
  FZF_PREVIEW_COLUMNS="$COLS" "$XDG_CONFIG_HOME/zsh/libexec/hr.sh"
  "${CURL[@]}" -- "$URI/search?format=json&pageno=$N&q=$QUERY" | "${J[@]}" | "${PAGE[@]}"
done | less
