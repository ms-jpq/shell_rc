#################### ############## ####################
#################### History Region ####################
#################### ############## ####################

export HISTORY_SUBSTRING_SEARCH_FUZZY=true
export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=true


# INTI #
source "$ZDOTDIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
# INIT #


bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
