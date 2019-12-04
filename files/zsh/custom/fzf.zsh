#################### ########## ####################
#################### FZF Region ####################
#################### ########## ####################

export FZFZ_SUBDIR_LIMIT=0

export FZF_DEFAULT_OPTS="--color light \
                         --height 40% \
                         --reverse \
                         --border"


alias f=' fzf'

d() {
  local candidates=$(fd -HI -t l -t d "$@" | sort -nf)
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
