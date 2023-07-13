#!/usr/bin/env -S -- bash

# shellcheck disable=SC2034
HISTORY_SUBSTRING_SEARCH_FUZZY=true
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=true

bindkey -- '^[[A' history-substring-search-up
bindkey -- '^[[B' history-substring-search-down

bindkey -- '^[OA' history-substring-search-up
bindkey -- '^[OB' history-substring-search-down

# shellcheck disable=SC1091
source -- "$HOME/.local/opt/zsh-history-substring-search/zsh-history-substring-search.zsh"
