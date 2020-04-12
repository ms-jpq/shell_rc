#################### ######### ####################
#################### LF Region ####################
#################### ######### ####################

alias lfq='lf -remote quit'

ff () {
  local LF_CD_FILE="$(mktemp)"
  LF_CD_FILE="$LF_CD_FILE" lf
  if [[ -s "$LF_CD_FILE" ]]
  then
    cd "$(cat "$LF_CD_FILE")" || return 1
  fi
}
