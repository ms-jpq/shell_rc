#################### ########### ####################
#################### Tmux Region ####################
#################### ########### ####################

alias tl='tmux list-sessions'

ta() {
  local sessions="$(tl -F '#{session_name}')"
  if [[ -z "$sessions" ]]
  then
    tmux new-session -A -s TMUX
  else
    local session="$(echo "$sessions" | fzf -1)"
    tmux attach -t "$session"
  fi
}
