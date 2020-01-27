#################### ############ ####################
#################### MacOS Region ####################
#################### ############ ####################


alias t='open -f'

alias batt='pmset -g batt'
alias dns='sudo killall -HUP mDNSResponder'


alias brewup='brew update -v && \
              brew upgrade -v && \
              brew cleanup -v && \
              brew doctor -v && \
              brew cask outdated -v'


vnc() {
  open "vnc://$1:${2-5900}"
}
