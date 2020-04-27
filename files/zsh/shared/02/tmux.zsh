#################### ########### ####################
#################### Tmux Region ####################
#################### ########### ####################

alias tl='tmux list-sessions'

ta() {
  local session="$(tl -F '#{session_name}' | fzf -0 -1)"
  tmux new-session -A -s "${session:-"MAIN"}"
}

