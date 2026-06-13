#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

M2="$HOME/.cache/m2"
mkdir -p -- "$M2"

exec -- ~/.local/libexec/flock.sh "$M2" clojure -Sdeps "{:mvn/local-repo \"$M2\"}" "$@"
