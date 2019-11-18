#################### ############ ####################
#################### MacOS Region ####################
#################### ############ ####################

alias c='pbcopy'
alias p='pbpaste'
alias t='open -f'

alias trash='trash -v'

alias batt='pmset -g batt'
alias dns='sudo killall -HUP mDNSResponder'

alias brewup='brew update && brew upgrade && brew cleanup && brew doctor && brew cask outdated'

ma() {
  man -t $1 | open -a Preview
}

vnc() {
  open "vnc://$1:${2-5900}"
}
