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

# Remember fx -- https://github.com/antonmedv/fx

