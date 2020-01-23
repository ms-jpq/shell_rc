#################### ########## ####################
#################### FZF Region ####################
#################### ########## ####################

export FZF_DEFAULT_OPTS="--color light \
                         --reverse \
                         --border"


alias fp='fzf --preview $FZF_PREVIEW'

f() {
  if [[ "$#" -eq 0 ]]
  then
    fzf
  else
    fzf -q "$@"
  fi
}


fe() {
  local file="$(fp "$@")"
  if [[ ! -z "$file" ]]
  then
    $EDITOR "$file"
  fi
}


cf() {
  local file="$(fp "$@")"
  if [[ ! -z "$file" ]]
  then
    cat "$file"
  fi
}


__fzf_jump() {
  local candidates="$1"
  if [[ -z "$candidates" ]]
  then
    echo "no such file or directory: $@"
  else
    cd "$(echo "$candidates" | fp -1 +s)"
  fi
}


ds() {
  __fzf_jump "$(fd -t l -t d "$@" | sort -nf)"
}


unalias z
z() {
  __fzf_jump "$(
    _z -l -r "$@" 2>&1 | sed -e "s/^[0-9]\+[ ]\+//" -e "/^common:[ ]\+/d" | tac
  )"
}
