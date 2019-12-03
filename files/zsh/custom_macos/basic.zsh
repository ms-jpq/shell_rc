#################### ############ ####################
#################### MacOS Region ####################
#################### ############ ####################


alias t='open -f'

alias ls=' exa --group-directories-first --time-style long-iso -ahF'
alias l='ls -1'
alias ll='ls -l'
alias tree='ls -T -L'

alias trash='trash -v'
alias rm='trash'

alias batt='pmset -g batt'
alias dns='sudo killall -HUP mDNSResponder'


alias brewup='brew update && brew upgrade && brew cleanup && brew doctor && brew cask outdated'

vnc() {
  open "vnc://$1:${2-5900}"
}
