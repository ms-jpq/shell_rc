#################### ######## ####################
#################### Z Region ####################
#################### ######## ####################

export _Z_DATA="$ZDOTDIR/z"

unalias z
z() {
  local A="$(_z -l "$@" 2>&1)"
  local B="$(echo "$A" | sed -e "s/^[0-9|\.]\+[ ]\+//" -e "/^common:[ ]\+/d")"
  if [[ -z "$B" ]]
  then
    echo "no such file or directory: $*"
  else
    local C="$(echo "$B" | fp -1 +s --tac)"
    cd "$C" || return 1
  fi
}
