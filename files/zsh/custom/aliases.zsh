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
alias f=' fzf'

alias m='micro'

alias gotop=' gotop -c lite'

alias rsy='rsync -ah --no-o --no-g --partial --info=progress2'

alias hist=' history'


#################### ########## ####################
#################### Dir Region ####################
#################### ########## ####################
alias cd=' cd'
# d() {
#   local target="$(dirs -p | awk '!a[$0]++' | fzf)"
#   local target="${target/#\~/$HOME}"
#   if [[ -d $target ]]
#   then
#     cd "$target"
#   else
#     echo "cd: no such file or directory: $target"
#   fi
# }
# alias d=' d'


#################### ########## ####################
#################### Man Region ####################
#################### ########## ####################
ma() {
  man $1 | col -b
}
