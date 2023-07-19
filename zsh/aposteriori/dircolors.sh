#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
if [[ -f "$XDG_CACHE_HOME/zsh/dircolors.sh" ]]; then
  # shellcheck disable=SC1091
  source -- "$XDG_CACHE_HOME/zsh/dircolors.sh"
fi
