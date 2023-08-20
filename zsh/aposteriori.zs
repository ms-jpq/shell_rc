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

zstyle ':fzf-tab:*' fzf-flags '--no-color'

# shellcheck disable=SC1091
source -- "$HOME/.local/opt/fzf-tab/fzf-tab.zsh"

# shellcheck disable=SC2034
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=4'
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(autosuggest-accept)

bindkey -- '^f' autosuggest-accept
bindkey -- '^[f' autosuggest-accept

# shellcheck disable=SC1091
source -- "$HOME/.local/opt/zsh-autosuggestions/zsh-autosuggestions.zsh"

# shellcheck disable=SC1091
source -- "$HOME/.local/opt/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
