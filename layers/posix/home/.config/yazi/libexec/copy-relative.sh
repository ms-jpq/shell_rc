#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

NAME="$*"

if TOP="$(git --no-optional-locks rev-parse --path-format=absolute --show-toplevel)"; then
  realpath --no-symlinks --relative-to "$TOP" -- "$NAME"
elif [[ $NAME == "$HOME"/* ]]; then
  # shellcheck disable=SC2088
  printf -- '%s' '~/'
  realpath --no-symlinks --relative-base "$HOME" -- "$NAME"
else
  printf -- '%s' "$NAME"
fi | sed -E -z -e 's/\n$//' | ~/.config/zsh/bin/c
