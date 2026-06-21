#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

set -x
while true; do
  kitten quick-access-terminal --override=start_as_hidden=yes || :
done 2>&1 | ts '%H:%M:%S'
