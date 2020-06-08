#################### ############### ####################
#################### Ruby Env Region ####################
#################### ############### ####################

export GEM_HOME="$XDG_DATA_HOME/gem"
export GEM_SPEC_CACHE="$XDG_CACHE_HOME/gem"


gem() {
  if rbenv local > /dev/null 2>&1
  then
    command gem "$@"
  else
    echo 'Not in rbenv - require explicit:'
    echo
    echo "command gem $*"
    echo
  fi
}

