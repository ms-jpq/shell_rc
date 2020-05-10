#################### ################## ####################
#################### Completions Region ####################
#################### ################## ####################

# INIT
fpath=("$ZDOTDIR/zsh-completions/src" $fpath)
# INIT


autoload -U compinit && compinit

compinit -u -C -d "$ZDOTDIR/.zcompdump-$ZSH_VERSION"
