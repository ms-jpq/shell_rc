#################### ############### ####################
#################### Node Env Region ####################
#################### ############### ####################

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


npmg() {
  local NPMG="$XDG_DATA_HOME/npm_global"
  local MODULES="$NPMG/node_modules"

  if [[ -d "$NPMG" ]]
  then
    paths add "$NPMG/node_modules"
  else
    mkdir -p "$MODULES"
    cd "$NPMG"
    yes $'\n' | npm init
    npm install
  fi
}

# Remember fx -- https://github.com/antonmedv/fx

