#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

F="$HOME/.fdignore"
if ! [[ -L "$F" ]]; then
  ln -v -sf -- "$HOME/.ignore" "$F"
fi
