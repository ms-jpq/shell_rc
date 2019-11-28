#################### ############ ####################
#################### MacOS Region ####################
#################### ############ ####################

alias c='pbcopy'
alias p='pbpaste'
alias t='open -f'


alias ls=' exa --group-directories-first -ahF '
alias l='ls -1 '
alias ll='ls -l --time-style iso'
alias tree='ls -T -L'


export BAT_THEME=GitHub
export BAT_PAGER=never
alias cat=" bat"


alias fd='fd -HI'


alias trash='trash -v'
alias rm='trash'


export FZF_DEFAULT_OPTS=--color light


alias batt='pmset -g batt'
alias dns='sudo killall -HUP mDNSResponder'


alias brewup='brew update && brew upgrade && brew cleanup && brew doctor && brew cask outdated'


ma() {
  man $1 | col -b | t
}

vnc() {
  open "vnc://$1:${2-5900}"
}
