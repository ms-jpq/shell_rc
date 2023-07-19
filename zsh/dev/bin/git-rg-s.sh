#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SEARCH=()
for RE in "$@"; do
  SEARCH+=(-G "$RE")
done

exec -- "${0%/*}/git-ls-c.sh" --all-match "${SEARCH[@]}"
