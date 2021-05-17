#################### ########### ####################
#################### Tmux Region ####################
#################### ########### ####################


if [[ -n "$TMUX" ]]
then
  alias cls='clear && tmux clear-history'
else
  alias cls='clear'
fi
