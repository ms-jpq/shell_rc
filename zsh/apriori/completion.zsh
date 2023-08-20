#!/usr/bin/env -S -- bash

setopt -- auto_list        # Show choices when ambiguous
setopt -- auto_menu        # Show completion menu on successive tab press
setopt -- auto_param_slash # Add trailing / to folder names
setopt -- list_ambiguous   # Only list if ambiguous


setopt -- complete_in_word # Comp both ends of words
setopt -- glob_complete    # Do not aggressively expand glob

# setopt -- no_menu_complete # Do not autoselect the first completion entry

# shellcheck disable=SC2034
WORDCHARS=''

# Case insensitive matches
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Cache completions:
zstyle ':completion::complete:*' use-cache on
# shellcheck disable=SC2154
zstyle ':completion::complete:*' cache-path "$XDG_CACHE_HOME/zsh/completion"
