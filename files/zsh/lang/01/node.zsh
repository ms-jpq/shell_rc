#################### ############### ####################
#################### Node Env Region ####################
#################### ############### ####################

export NODE_REPL_HISTORY="$XDG_CACHE_HOME/node_hist"
export npm_config_cache="$XDG_CACHE_HOME/npm"


np() {
  paths show | rg 'node_modules' | while read p
  do
    paths remove "$p"
  done
  local this="$PWD/node_modules/.bin"
  if [[ -d "$this" ]]
  then
    paths add "$this"
  else
    echo "RESET -- npm PATH"
  fi
}

# Remember fx -- https://github.com/antonmedv/fx
