#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

GOOD="$1"
BAD="$2"
shift -- 2

git bisect start "$BAD" "$GOOD"
git bisect run "$@"
git bisect log
git bisect reset
