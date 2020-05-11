#################### ############## ####################
#################### Loading Region ####################
#################### ############## ####################

zsh_main() {
  local zrc_targets=(
    apriori
    intrinsic
    shared
    distro
    plugins
  )

  for target in "${zrc_targets[@]}"
  do
    local rcs="$XDG_CONFIG_HOME/zsh/$target"
    for rc in "$rcs"/**/*.zsh
    do
      source "$rc"
    done
  done
}

zsh_main

