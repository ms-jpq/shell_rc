#################### ############### ####################
#################### Node Env Region ####################
#################### ############### ####################

export NODE_REPL_HISTORY="$XDG_CACHE_HOME/node_hist"
export npm_config_cache="$XDG_CACHE_HOME/npm"


np() {
  paths show 2>&1 | rg -F0 'node_modules' | while read -r -d $'\0' p
  do
    paths remove "$p"
  done

  local this="$PWD/node_modules/.bin"
  if [[ -d "$this" ]]
  then
    paths add "$this"
  else
    echo 'RESET  -- npm PATH'
  fi
}

# Remember fx -- https://github.com/antonmedv/fx

