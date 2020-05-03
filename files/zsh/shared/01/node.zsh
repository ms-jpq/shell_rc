#################### ############### ####################
#################### Node Env Region ####################
#################### ############### ####################

if [[ "$SHLVL" -eq 1 ]]
then
  export NODENV_ROOT="$XDG_CONFIG_HOME/nodenv"
  export PATH="$NODENV_ROOT/bin:$PATH"
fi
eval "$(nodenv init -)"


alias np='PATH="$PWD/node_modules/.bin:$PATH" '
alias npx='export PATH="$PWD/node_modules/.bin:$PATH"'
