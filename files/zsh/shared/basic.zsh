#################### ########### ####################
#################### Core Region ####################
#################### ########### ####################

export PAGER='less'
export LESS="--quit-on-intr \
             --quit-if-one-screen \
             --mouse \
             --RAW-CONTROL-CHARS \
             --tilde \
             --tabs=2 \
             --QUIET \
             --ignore-case \
             --no-histdups"
export BROWSER='firefox'


# Safety
alias rm='rm -I'
alias mv='mv -i'
alias cp='cp -i'
# Safety


alias mkdir='mkdir -p'

alias cls='clear'
alias sudo='sudo --preserve-env -- '
alias cmd='command '


export TIME_STYLE='long-iso'
alias ls='exa --group-directories-first --icons --header --classify'
alias l='ls --oneline'
alias ll='ls --long --group'
tree() {
  ls --tree --level="${1:-2}"
}


export BAT_THEME=GitHub
# export BAT_THEME=ansi-dark
export BAT_STYLE=plain
alias cat='bat'


paths() {
  export PATH="$(command paths "$@")"
}

#################### ################ ####################
#################### Auxiliary Region ####################
#################### ################ ####################

proxy() {
  if [[ "$#" -eq 0 ]]
  then
    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
  else
    export http_proxy="http://${2:-localhost}:$1"
    export https_proxy="$http_proxy"
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$http_proxy"
  fi
  printf '%s\n' "http_proxy =$http_proxy"
  printf '%s\n' "https_proxy=$https_proxy"
}


export WGETRC="$XDG_CONFIG_HOME/wgetrc"

alias rsy='rsync -ah --no-o --no-g --info progress2'
