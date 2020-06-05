#################### ############## ####################
#################### Loading Region ####################
#################### ############## ####################

zsh_main() {
  local zrc_targets=(
    apriori
    shared
    "$(uname | tr '[:upper:]' '[:lower:]')"
    lang
    plugins
    aposteriori
  )

  for rc in "$XDG_CONFIG_HOME/zsh/intrinsic"/**/*.zsh
  do
    source "$rc"
  done

  for target in "${zrc_targets[@]}"
  do
    local rcs="$XDG_CONFIG_HOME/zsh/rc/$target"
    for rc in "$rcs"/**/*.zsh
    do
      source "$rc"
    done
  done
}

zsh_main
unset -f zsh_main
