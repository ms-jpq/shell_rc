#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

gawk --pretty-print=/dev/stdout --file=/dev/stdin | sed -E -e 's#\t#  #g'
