#################### ########### ####################
#################### Core Region ####################
#################### ########### ####################

# NEVER USE IT DIRECTLY #
# alias rm='echo 🦄'
# NEVER USE IT DIRECTLY #

alias cls='clear'

alias c='clipcopy'
alias p='clippaste'

alias sudo='sudo -E '

alias ls='exa --group-directories-first -hF'
alias l='ls -1'
alias ll='ls -lg'
alias tree='ls -T -L'

alias cat='bat'

alias hist='history'

alias m='micro'

alias trash='trash -v'

alias rsy='rsync -ah --no-o --no-g --info progress2'

alias gt='gotop -c lite'


ma() {
  man "$1" | col -b
}

alias srv='python3 -m http.server'

proxy() {
  if [ "$#" -eq 0 ]
  then
    unset http_proxy
    unset https_proxy
  else
    export http_proxy="http://${2-localhost}:$1"
    export https_proxy="http://${2-localhost}:$1"
  fi
  echo "http_proxy=$http_proxy"
  echo "https_proxy=$https_proxy"
}
