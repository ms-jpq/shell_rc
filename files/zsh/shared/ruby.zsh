#################### ############### ####################
#################### Ruby Env Region ####################
#################### ############### ####################

gem() {
  if rbenv local > /dev/null 2>&1
  then
    command gem "$@"
  else
    printf '%s\n' 'Not in rbenv - require explicit:'
    printf '%s\n'
    printf '%s\n' "command gem $*"
    printf '%s\n'
  fi
}

