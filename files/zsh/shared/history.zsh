#!/usr/bin/env bash

#################### ############## ####################
#################### History Region ####################
#################### ############## ####################

# INTI #
HISTORY_SUBSTRING_SEARCH_FUZZY=true
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=true
source "$ZDOTDIR/../zsh-history-substring-search/zsh-history-substring-search.zsh"
# INIT #


bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down
