#################### ########### ####################
#################### Core Region ####################
#################### ########### ####################

# NEVER USE IT DIRECTLY #
alias rm='echo 🦄'
# NEVER USE IT DIRECTLY #

alias cls='clear'

alias c='clipcopy'
alias p='clippaste'

alias sudo='sudo -E '

alias cat='bat'

alias fd='fd -H'

alias m='micro'

alias gotop='gotop -c lite'

alias rsy='rsync -ah --no-o --no-g --partial --info=progress2'

alias hist='history'

ma() {
  man "$1" | col -b
}
