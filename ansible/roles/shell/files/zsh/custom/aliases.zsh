#################### ########### ####################
#################### Core Region ####################
#################### ########### ####################

alias sudo='sudo -E '

if type exa > /dev/null
then
  alias ls='exa --group-directories-first -ahF '
  alias l='ls -1 '
  alias ll='ls -l '
  tree() {
    exa --group-directories-first -ahF -T -L ${1-9999}
  }
else
  alias ls='ls -hAF --color --group-directories-first'
  alias l='ls -1'
  alias ll='l -l'
  tree() {
    command tree -L ${1-9999}
  }
fi


if type bat > /dev/null
then
  alias cat="bat --pager never --theme GitHub"
fi


alias hist='history'

alias nano='nano -glm -$'

alias rsy='rsync -ah --no-o --no-g --partial --info=progress2'


#################### ############### ####################
#################### Anisible Region ####################
#################### ############### ####################


#################### ########## ####################
#################### GIT Region ####################
#################### ########## ####################

gitlines() {
  git ls-files | grep "$@" | xargs wc -l
}
