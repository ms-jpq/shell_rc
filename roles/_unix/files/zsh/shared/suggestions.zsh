#!/usr/bin/env bash

#################### ################## ####################
#################### AutoSuggest Region ####################
#################### ################## ####################

# INTI #
ZSH_AUTOSUGGEST_USE_ASYNC=true \
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=4' \
source "$ZDOTDIR/../zsh-autosuggestions/zsh-autosuggestions.zsh"
# INIT #


bindkey '^ ' autosuggest-accept
