#################### ########## ####################
#################### GIT Region ####################
#################### ########## ####################

export GIT_PAGER='diff-so-fancy | less'

alias lg='lazygit'

gitlines() {
  git ls-files | rg "$@" | xargs wc -l
}
