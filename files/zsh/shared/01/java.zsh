#################### ############### ####################
#################### Java Env Region ####################
#################### ############### ####################

export JENV_ROOT="$XDG_CONFIG_HOME/jenv"
if [[ "$SHLVL" -eq 1 ]]
then
  export PATH="$JENV_ROOT/bin:$PATH"
fi
eval "$(jenv init -)"
