#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if [[ -v TMUX ]]; then
  # shellcheck disable=SC2154
  exec -- tmux new-window -- "$EDITOR" "$@"
else
  exec -- open -- "$@"
fi
