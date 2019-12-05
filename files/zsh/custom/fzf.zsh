#################### ########## ####################
#################### FZF Region ####################
#################### ########## ####################

export FZF_DEFAULT_OPTS="--color light \
                         --height 40% \
                         --reverse \
                         --border
                         --preview '$FZF_PREVIEW'"

alias f=' fzf'

fe() {
  local file="$(fzf)"
  [[ ! -z "$file" ]] && $EDITOR "$file"
}


__fzf_jump() {
  local candidates="$1"
  if [[ -z "$candidates" ]]
  then
    echo "no such file or directory: $@"
  else
    cd "$(echo "$candidates" | fzf -1 +s)"
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
