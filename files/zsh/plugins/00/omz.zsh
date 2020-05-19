#################### ########## ####################
#################### OMZ Region ####################
#################### ########## ####################

omz_main() {
  export ZSH_CACHE_DIR="$XDG_CACHE_HOME"

  local plugins=(
    fd
    ripgrep
    colorize
    # docker
    # kubectl
    # helm
  )

  for plugin in "${plugins[@]}"
  do
    local plug="$XDG_CONFIG_HOME/zsh/oh-my-zsh/plugins/$plugin"
    fpath=("$plug" $fpath)
  done

  # INIT #
  compinit -u -C -d "$XDG_CACHE_HOME/zcompdump-$ZSH_VERSION"
  # INIT #

  for plugin in "${plugins[@]}"
  do
    local plug="$XDG_CONFIG_HOME/zsh/oh-my-zsh/plugins/$plugin"
    local p="$plug/$plugin.plugin.zsh"
    if [[ -f "$p" ]]
    then
      source "$p"
    fi
  done

  unset ZSH_CACHE_DIR
}

omz_main
unset -f omz_main
