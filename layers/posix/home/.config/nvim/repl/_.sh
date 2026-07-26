#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

FILE="$1"
PANE="$4"

{
  cat -- "$FILE"
} | ~/.config/tmux/libexec/send-text.sh "$PANE"
