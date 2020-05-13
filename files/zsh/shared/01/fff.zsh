#################### ########### ####################
#################### NAVI Region ####################
#################### ########### ####################

fff() {
  local FFF_CD_FILE="$(mktemp)"
  FFF_CD_FILE="$FFF_CD_FILE" command fff "$@"
  cd "$(cat "$FFF_CD_FILE")" || return 1
}
