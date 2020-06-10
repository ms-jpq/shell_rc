#################### ##################### ####################
#################### Instant Prompt Region ####################
#################### ##################### ####################

if [[ -r "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh" ]]
then
  source "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh"
fi


#################### ############## ####################
#################### Loading Region ####################
#################### ############## ####################

zsh_main() {
  local zrc_targets=(
    apriori
    shared
    "$(uname | tr '[:upper:]' '[:lower:]')"
    aposteriori
  )

  for rc in "$XDG_CONFIG_HOME/zsh/intrinsic"/**/*.zsh(N)
  do
    source "$rc"
  done

  for target in "${zrc_targets[@]}"
  do
    local rcs="$XDG_CONFIG_HOME/zsh/rc/$target"
    for rc in "$rcs"/**/*.zsh(N)
    do
      source "$rc"
    done
  done
}

zsh_main
unset -f zsh_main

