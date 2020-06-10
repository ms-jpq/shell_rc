#################### ########## ####################
#################### Git Region ####################
#################### ########## ####################

export GIT_PAGER='delta --paging=never | less'

alias lg='lazygit'

alias gtm='git-time-machine'

gitlines() {
  git ls-files | rg "$@" | xargs wc -l
}

