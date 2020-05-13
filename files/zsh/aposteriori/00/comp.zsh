#################### ################## ####################
#################### Completions Region ####################
#################### ################## ####################

# INIT #
autoload -U -z compinit
autoload -U +X bashcompinit
compinit -u -C -d "$XDG_CACHE_HOME/zcompdump-$ZSH_VERSION"
bashcompinit
# INIT #

