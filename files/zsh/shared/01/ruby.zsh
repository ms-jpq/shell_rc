#################### ############### ####################
#################### Ruby Env Region ####################
#################### ############### ####################

export RBENV_ROOT="$XDG_CONFIG_HOME/rbenv"
if [[ "$SHLVL" -eq 1 ]]
then
  export PATH="$RBENV_ROOT/bin:$PATH"
fi
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
