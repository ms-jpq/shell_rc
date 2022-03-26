#!/usr/bin/env bash

#################### ################## ####################
#################### AutoSuggest Region ####################
#################### ################## ####################

# INTI #
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=4'
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(autosuggest-accept)
source "$ZDOTDIR/../zsh-autosuggestions/zsh-autosuggestions.zsh"
# INIT #


bindkey '^ ' autosuggest-accept
bindkey '^[ ' autosuggest-accept
