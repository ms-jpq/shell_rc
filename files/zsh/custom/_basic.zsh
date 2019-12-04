#################### ########### ####################
#################### Core Region ####################
#################### ########### ####################

alias c='clipcopy'
alias p='clippaste'

alias cls=' clear'

alias sudo='sudo -E '

alias cat=" bat"
alias ccat=' ccat'

alias fd='fd -HI'
alias cd=' cd'

alias m='micro'

alias gotop=' gotop -c lite'

alias rsy='rsync -ah --no-o --no-g --partial --info=progress2'

alias hist=' history'

ma() {
  man $1 | col -b
}
