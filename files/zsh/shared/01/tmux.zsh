#################### ########### ####################
#################### Tmux Region ####################
#################### ########### ####################

if [[ -n "$TMUX" ]]
then
  PATH="$XDG_CONFIG_HOME/tmux/bin:$PATH"
fi


alias tl='tmux list-sessions'


ta() {
  if [[ $# -ne 0 ]]
  then
    tmux new-session -A -s "$*"
  else
    local session
    session="$(tl -F '#{session_name}' | fzf -0 -1)"
    if [[ $? -eq 130 ]]
    then
      return
    fi
    tmux new-session -A -s "${session:-"owo"}"
  fi
}

