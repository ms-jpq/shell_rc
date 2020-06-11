#################### ############### ####################
#################### Node Env Region ####################
#################### ############### ####################

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

