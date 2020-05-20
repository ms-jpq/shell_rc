#################### ########## ####################
#################### GIT Region ####################
#################### ########## ####################

export GIT_PAGER='delta --paging=never | less'

alias lg='lazygit'

gitlines() {
  git ls-files | rg "$@" | xargs wc -l
}
