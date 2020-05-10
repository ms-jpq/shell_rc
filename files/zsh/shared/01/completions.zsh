#################### ################## ####################
#################### Completions Region ####################
#################### ################## ####################

unsetopt menu_complete   # do not autoselect the first completion entry
unsetopt flowcontrol
setopt auto_menu         # show completion menu on successive tab press
setopt complete_in_word
setopt always_to_end


export WORDCHARS=''


# INIT #
autoload -U compinit && compinit
autoload -U +X bashcompinit && bashcompinit
compinit -u -C -d "$XDG_CACHE_HOME/zcompdump-$ZSH_VERSION"
# INIT #


# Case insensitive matches
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Cache completions:
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path "$XDG_CACHE_HOME/zsh"

