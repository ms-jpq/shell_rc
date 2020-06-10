#################### ######### ####################
#################### Rg Region ####################
#################### ######### ####################

export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/rg.conf"

rgf() {
  local OPTIONS='--color=always \
                 --context=2 \
                 --context-separator="$(hr "-" "$FZF_PREVIEW_COLUMNS")"'

  rg "$@" --files-with-matches | fzf --preview="rg $OPTIONS $* {}"
}

