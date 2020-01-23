#################### ########### ####################
#################### Core Region ####################
#################### ########### ####################

# NEVER USE IT DIRECTLY #
# alias rm='echo 🦄'
# NEVER USE IT DIRECTLY #

alias cls='clear'

alias c='clipcopy'
alias p='clippaste'

alias sudo='sudo -E '

alias ls='exa --group-directories-first -hF'
alias l='ls -1'
alias ll='ls -l'
alias tree='ls -T -L'

alias cat='bat'

alias hist='history'

alias m='micro'

alias trash='trash -v'

alias rsy='rsync -ah --no-o --no-g --info progress2'

alias gotop='gotop -c lite'


ma() {
  man "$1" | col -b
}
