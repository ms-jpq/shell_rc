#################### ########### ####################
#################### Core Region ####################
#################### ########### ####################

alias c='clipcopy'
alias p='clippaste'

alias sudo='sudo -E '

alias cd=' cd'
alias 0='cd'

alias hist=' history'

alias m='micro'

alias rsy='rsync -ah --no-o --no-g --partial --info=progress2'

ma() {
  man $1 | col -b
}
