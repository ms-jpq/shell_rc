#################### ############### ####################
#################### Node Env Region ####################
#################### ############### ####################

export NPM_GLOBAL_BIN="$XDG_DATA_HOME/npm_global/node_modules/.bin"
export PATH="$NPM_GLOBAL_BIN:$PATH"


np() {
  local modules='node_modules/.bin'
  local LFS=$'\0'
  paths show 2>&1 | rg -F0 "$modules" | while read -r p
  do
    paths remove "$p"
  done

  local this="$modules"
  if [[ -d "$this" ]]
  then
    paths add -r "$this"
  else
    printf '%s\n' 'RESET  -- npm PATH'
  fi
}

