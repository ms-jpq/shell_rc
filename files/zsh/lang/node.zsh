#################### ############### ####################
#################### Node Env Region ####################
#################### ############### ####################

export NODENV_ROOT="$XDG_DATA_HOME/nodenv"
if [[ "$SHLVL" -eq 1 ]]
then
  export PATH="$NODENV_ROOT/bin:$PATH"
fi
eval "$(nodenv init - --no-rehash)"


export NODE_REPL_HISTORY="$XDG_CACHE_HOME/node_hist"
export npm_config_cache="$XDG_CACHE_HOME/npm"


alias np='PATH="$PWD/node_modules/.bin:$PATH" '
alias npx='export PATH="$PWD/node_modules/.bin:$PATH"'
