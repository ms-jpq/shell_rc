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
d() {
  local candidates=$(fd -t d "$@" | sort -nf)
  if [[ -z $candidates ]]
  then
    echo "no such file or directory: $@"
  elif [[ $(echo $candidates | wc -l) -eq 1 ]]
  then
    cd "$candidates"
  else
    cd "$(echo $candidates | fzf --preview "$FZF_DIR_PREVIEW")"
  fi
}
alias d=' d'


#################### ########## ####################
#################### Man Region ####################
#################### ########## ####################
ma() {
  man $1 | col -b
}
