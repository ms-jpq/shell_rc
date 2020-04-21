#################### ############### ####################
#################### Ruby Env Region ####################
#################### ############### ####################

export PATH="$XDG_CONFIG_HOME/rbenv/bin:$PATH"
eval "$(rbenv init -)"


gem() {
  if rbenv local > /dev/null 2>&1
  then
    command gem "$@"
  else
    echo "Not in rbenv - require explicit:"
    echo
    echo "command gem $*"
    echo
  fi
}
