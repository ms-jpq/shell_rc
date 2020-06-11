#################### ############### ####################
#################### Node Env Region ####################
#################### ############### ####################

export NODE_REPL_HISTORY="$XDG_CACHE_HOME/node_hist"
export npm_config_cache="$XDG_CACHE_HOME/npm"


np() {
  local LFS=$'\0'
  paths show 2>&1 | rg -F0 'node_modules' | while read -r p
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

