#################### ######## ####################
#################### Z Region ####################
#################### ######## ####################

# INIT
_Z_CMD='__z' . "$ZDOTDIR/z/z.sh"
# INIT #


z() {
  local A="$(_z -l "$*" 2>&1)"
  local B="$(sd '^[[\d|\.]|common:]+\s+' '' <<< "$A" | awk '!seen[$0]++')"
  if [[ -z "$B" ]]
  then
    printf '%s\n' "no such file or directory: $*"
  else
    local C="$(fp -1 +s --tac <<< "$B")"
    cd "$C" || return 1
  fi
}

