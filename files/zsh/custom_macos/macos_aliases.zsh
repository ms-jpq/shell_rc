#################### ############### ####################
#################### Homebrew Region ####################
#################### ############### ####################

alias ls=' exa --group-directories-first -ahF '
alias l='ls -1 '
alias ll='ls -l '
alias tree='ls -T -L'

alias cat=" bat --pager never --theme GitHub"

#################### ############ ####################
#################### MacOS Region ####################
#################### ############ ####################

alias c='pbcopy'
alias p='pbpaste'
alias t='open -f'

alias trash='trash -v'
alias rm='trash'

alias batt='pmset -g batt'
alias dns='sudo killall -HUP mDNSResponder'

alias brewup='brew update && brew upgrade && brew cleanup && brew doctor && brew cask outdated'

ma() {
  man $1 | col -b | t
}

vnc() {
  open "vnc://$1:${2-5900}"
}
