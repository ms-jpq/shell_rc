#################### ########## ####################
#################### DEV Region ####################
#################### ########## ####################

git-ssh() {
  if [[ $# -eq 0 ]]
  then
    unset GIT_SSH_COMMAND
  else
    export GIT_SSH_COMMAND="$(command git-ssh "$@")"
  fi
}