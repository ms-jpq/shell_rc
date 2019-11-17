#################### ############ ####################
#################### MacOS Region ####################
#################### ############ ####################

alias trash='trash -v'

alias batt='pmset -g batt'
alias dns='sudo killall -HUP mDNSResponder'

alias brewup='brew update && brew upgrade && brew cleanup && brew doctor && brew cask outdated'

alias mp='multipass'

ma() {
  man -t $1 | open -fa Preview
}

vnc() {
  open "vnc://$1:${2-5900}"
}
