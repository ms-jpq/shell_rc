#################### ########## ####################
#################### OMZ Region ####################
#################### ########## ####################

omz_main() {
  export ZSH_CACHE_DIR="$XDG_CACHE_HOME"

  local plugins=(
    fd
    ripgrep
    colorize
    docker
    kubectl
    helm
  )

  for plugin in "${plugins[@]}"
  do
    local plug="$XDG_CONFIG_HOME/zsh/oh-my-zsh/plugins/$plugin"
    local p="$plug/_$plugin"
    if [[ ! -f "$p" ]]
    then
      p="$plug/$plugin.plugin.zsh"
      source "$p"
    fi
    fpath=("$p" $fpath)
  done

  unset ZSH_CACHE_DIR
}

omz_main
unset -f omz_main
