#################### ########## ####################
#################### FZF Region ####################
#################### ########## ####################

export FZF_DEFAULT_OPTS="--color light \
                         --height 40% \
                         --reverse \
                         --border
                         --preview '$FZF_PREVIEW'"

alias f=' fzf'

__fzf_jump() {
  local candidates="$1"
  if [[ -z "$candidates" ]]
  then
    echo "no such file or directory: $@"
  elif [[ $(echo "$candidates" | wc -l) -eq 1 ]]
  then
    cd "$candidates"
  else
    cd "$(echo "$candidates" | fzf +s)"
  fi
}


__d() {
  __fzf_jump "$(fd -t l -t d "$@" | sort -nf)"
}
alias d=' __d'


__z() {
  __fzf_jump "$(
    _z -lr "$@" 2>&1 | sed -e "s/^[0-9]\+[ ]\+//" -e "/^common:[ ]\+/d" | tac
  )"
}
alias z=' __z'
