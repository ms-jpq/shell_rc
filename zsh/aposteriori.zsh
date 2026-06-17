#!/usr/bin/env -S -- bash

autoload -Uz -- bashcompinit
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
  bashcompinit
}

_comp_init
unset -f -- _comp_init

_fzf_tab="$HOME/.local/opt/fzf-tab/fzf-tab.zsh"
if [[ -f $_fzf_tab ]]; then
  zstyle ':fzf-tab:*' fzf-flags '--no-color'

  # shellcheck disable=SC1091
  source -- "$HOME/.local/opt/fzf-tab/fzf-tab.zsh"
fi
unset -- _fzf_tab

# shellcheck disable=SC2034
ZSH_AUTOSUGGEST_USE_ASYNC=true
# shellcheck disable=SC2034
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=4'
# shellcheck disable=SC2034
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(autosuggest-accept)

bindkey -- '^f' autosuggest-accept
bindkey -- '^[f' autosuggest-accept

case "$OSTYPE" in
linux* | msys | cygwin)
  # shellcheck disable=SC1091
  source -- '/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
  # shellcheck disable=SC1091
  source -- '/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
  ;;
darwin*)
  # shellcheck disable=SC1091
  source -- '/opt/homebrew/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
  # shellcheck disable=SC1091
  source -- '/opt/homebrew/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
  ;;
*)
  ;;
esac


for _sh in ~/.local/lprofile.d/*.zsh; do
  # shellcheck disable=SC1090
  source -- "$_sh"
done
