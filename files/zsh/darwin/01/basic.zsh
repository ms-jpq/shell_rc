#################### ############ ####################
#################### MacOS Region ####################
#################### ############ ####################

alias p='pbpaste'
alias t='open -f'

alias batt='pmset -g batt'
alias dns='sudo killall -HUP mDNSResponder'


alias brewup="brew update && \
              brew upgrade && \
              brew cleanup && \
              brew doctor && \
              brew cask outdated"


alias trash='trash -v'


vnc() {
  open "vnc://$1:${2:-5900}"
}

resetpad() {
  defaults write com.apple.dock ResetLaunchPad -bool true
  killall Dock
}
