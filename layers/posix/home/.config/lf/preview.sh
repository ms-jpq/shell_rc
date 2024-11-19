#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TARGET="$1"
_WIDTH="$2"
_HEIGHT="$3"
_H_POS="$4"
_V_POS="$5"

exec -- bat --color always --- "$TARGET"
