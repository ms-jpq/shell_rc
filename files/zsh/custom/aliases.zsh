#################### ########### ####################
#################### Core Region ####################
#################### ########### ####################

alias c='clipcopy'
alias p='clippaste'

alias sudo='sudo -E '

alias cd=' cd'
alias 0='cd'

# alias cat=" bat"
alias cat=' ccat'

alias f=' fzf'

alias m='micro'

alias rsy='rsync -ah --no-o --no-g --partial --info=progress2'

alias hist=' history'

ma() {
  man $1 | col -b
}
