#################### ########## ####################
#################### GIT Region ####################
#################### ########## ####################

if [[ "$SHLVL" -eq 1 ]]
then
  export PATH="$XDG_CONFIG_HOME/gitrc:$PATH"
fi


export GIT_PAGER='delta --paging=never | less'

alias lg='lazygit'

gitlines() {
  git ls-files | rg "$@" | xargs wc -l
}
