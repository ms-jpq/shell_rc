#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

b3sum --no-names --length 8 -- "$@" | perl -CASD -wpe 's/(.{4})(?=.)/$1:/g'
