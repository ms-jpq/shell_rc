#################### ########### ####################
#################### Tmux Region ####################
#################### ########### ####################

alias tl='tmux list-sessions'

ta() {
  local session="$(tl -F '#{session_name}' | fzf -0 -1)"
  if [[ -z "$session" ]]
  then
    unset session
  fi
  tmux new-session -A -s "${session:-"MAIN"}"
}
