#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

URIS=(
  'https://wttr.in?m&format=4'
  'https://wttr.in?mT'
  'https://v2.wttr.in?mT'
)

URI="${URIS[$((RANDOM % ${#URIS[@]}))]}"

CURL=(
  curl
  --fail
  --no-progress-meter
)

if [[ -v LC_ALL ]]; then
  CURL+=(--header "Accept-Language: ${LC_ALL%_*}")
fi

CURL+=(-- "$URI")

exec -- "${CURL[@]}"
