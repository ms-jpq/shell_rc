#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LOCAL="$1"
REMOTE="$2"

TMP="$(mktemp -d)"
HTML="$TMP/index.html"

GIT=(
  env -i
  -- git
  --no-optional-locks
  diff
  --no-index
  -- "$LOCAL" "$REMOTE"
)
DIFF=(
  ~/.local/asdf/shims/npm exec
  --yes
  -- diff2html-cli
  --style side
  --input stdin
  --file "$HTML"
)
"${GIT[@]}" | "${DIFF[@]}" || true
open "$HTML"
