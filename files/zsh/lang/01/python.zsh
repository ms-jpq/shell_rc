#################### ################# ####################
#################### Python Env Region ####################
#################### ################# ####################

export PYTHONSTARTUP="$XDG_CONFIG_HOME/pythonrc.py"


pip3() {
  if [[ -z "$VIRTUAL_ENV" ]]
  then
    echo 'Not in virtualenv - require explicit:'
    echo
    echo "command pip $*"
    echo
  else
    command pip3 "$@"
  fi
}
alias pip='pip3'


alias python='python3'
alias py='python3'
alias pd='pydoc'
alias srv='python3 -m http.server'
