#!/usr/bin/env bash

#################### ################## ####################
#################### AutoSuggest Region ####################
#################### ################## ####################

# INTI #
export ZSH_AUTOSUGGEST_USE_ASYNC=true
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=4'
export ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(autosuggest-accept)
source "$ZDOTDIR/../zsh-autosuggestions/zsh-autosuggestions.zsh"
# INIT #


bindkey '^ ' autosuggest-accept
