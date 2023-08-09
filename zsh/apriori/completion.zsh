#!/usr/bin/env -S -- bash

setopt always_to_end    # move cursor to end of word
setopt auto_menu        # show completion menu on successive tab press
setopt auto_param_slash # add trailing / to folder names

setopt noflowcontrol

setopt complete_in_word # comp both ends of words
setopt glob_complete    # do not aggressively expand glob

setopt no_menu_complete # do not autoselect the first completion entry

# shellcheck disable=SC2034
WORDCHARS=''

# Case insensitive matches
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Cache completions:
zstyle ':completion::complete:*' use-cache on
# shellcheck disable=SC2154
zstyle ':completion::complete:*' cache-path "$XDG_CACHE_HOME/zsh/completion"
