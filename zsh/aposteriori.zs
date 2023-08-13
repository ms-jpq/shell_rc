#!/usr/bin/env -S -- bash

autoload -Uz -- compinit

# shellcheck disable=SC1036,SC2120
_comp_init() {
  # shellcheck disable=SC2154
  local -- dump="$XDG_CACHE_HOME/zsh/zcompdump" f=()
  # shellcheck disable=SC2034
  f=("$dump"(Nm-6))
  if (($#f)); then
    f=(-C)
  fi
  compinit -i "${f[@]}" -d "$dump"
}

_comp_init
unset -f -- _comp_init

# shellcheck disable=SC1091
source -- "$HOME/.local/opt/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
