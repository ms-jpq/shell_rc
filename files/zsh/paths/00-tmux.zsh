#################### ########### ####################
#################### Tmux Region ####################
#################### ########### ####################

alias cls='clear'

if [[ -n "$TMUX" ]]
then
  pathprepend "$XDG_CONFIG_HOME/tmux/bin"

  alias cls='clear && tmux clear-history'
fi
