#################### ################## ####################
#################### Completions Region ####################
#################### ################## ####################


setopt always_to_end     # move cursor to end of word
setopt auto_menu         # show completion menu on successive tab press
setopt auto_param_slash  # add trailing / to folder names

setopt noflowcontrol

setopt complete_in_word  # comp both ends of words
setopt glob_complete     # do not aggressively expand glob

setopt no_menu_complete  # do not autoselect the first completion entry


export WORDCHARS=''


# Case insensitive matches
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Cache completions:
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$XDG_CACHE_HOME/zsh_comp"


# INIT
autoload -Uz compinit
# INIT
