#################### ############ ####################
#################### Emacs Region ####################
#################### ############ ####################

alias e='emacs'
alias ec='emacsclient -t'

alias ep='touch .projectile'

ee() {
  if emacs_running
  then
    ec
  else
    e
  fi
}
