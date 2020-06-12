#################### ############### ####################
#################### Node Env Region ####################
#################### ############### ####################

export NPM_GLOBAL_HOME="$XDG_DATA_HOME/npm_global"

_npmg() {
  local npm_bin="$NPM_GLOBAL_HOME/node_modules/.bin"
  if [[ -d "$npm_bin" ]]
  then
    export PATH="$npm_bin:$PATH"
  fi
}
_npmg
unset -f _npmg


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

