#!/usr/bin/env -S -- bash

# INTI #
# shellcheck disable=SC2034
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=4'
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(autosuggest-accept)
# shellcheck disable=SC1091
source -- "$ZDOTDIR/../zsh-autosuggestions/zsh-autosuggestions.zsh"
# INIT #

bindkey '^f' autosuggest-accept
bindkey '^[f' autosuggest-accept
