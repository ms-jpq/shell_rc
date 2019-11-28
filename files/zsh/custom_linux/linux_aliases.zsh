#################### ############## ####################
#################### Display Region ####################
#################### ############## ####################

alias ls=' ls --group-directories-first --color -hAF '
alias l='ls -1 '
alias ll='ls -l '
alias tree=' tree -L'

#################### ############## ####################
#################### Display Region ####################
#################### ############## ####################

alias open=' xdg-open'

alias 1440='xrandr -s 2560x1440'
alias 1200='xrandr -s 1920x1200'
alias 800='xrandr -s 1280x800'

ma() {
  man $1 | col -b
}

alias c='it2copy'
