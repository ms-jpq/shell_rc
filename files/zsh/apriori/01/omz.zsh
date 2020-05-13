#################### ########## ####################
#################### OMZ Region ####################
#################### ########## ####################

omz_main() {
  local plugins=(
    # fd
    # ripgrep
    colorize
    docker
    # kubectl
    helm
  )

  for plugin in "${plugins[@]}"
  do
    local plug="$XDG_CONFIG_HOME/zsh/oh-my-zsh/plugins/$plugin"
    local p="$plug/_$plugin"
    if [[ ! -f "$p" ]]
    then
      p="$plug/$plugin.plugin.zsh"
    fi
    source "$p"
  done
}

omz_main
unset -f omz_main
