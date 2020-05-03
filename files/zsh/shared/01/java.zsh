#################### ############### ####################
#################### Java Env Region ####################
#################### ############### ####################

if [[ "$SHLVL" -eq 1 ]]
then
  export JENV_ROOT="$XDG_CONFIG_HOME/jenv"
  export PATH="$JENV_ROOT/bin:$PATH"
fi
eval "$(jenv init -)"
