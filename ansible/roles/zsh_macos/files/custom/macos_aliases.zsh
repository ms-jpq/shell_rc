
#################### ############## ####################
#################### Display Region ####################
#################### ############## ####################

alias trash='trash -v'

alias batt='pmset -g batt'
alias dns='killall -HUP mDNSResponder'

alias brewup='brew update && brew upgrade && brew cleanup && brew doctor'

ma() {
  man -t $1 | open -fa Preview
}

vnc() {
  open "vnc://$1:${2-5900}"
}
