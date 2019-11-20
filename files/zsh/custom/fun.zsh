#################### ########## ####################
#################### Fun Region ####################
#################### ########## ####################

gay() {
  local TEXT="'$*'"
  figlet "$TEXT" | lolcat -a -d 1 -s 250
}

cow() {
  local TEXT="'$*'"
  if [[ $((RANDOM % 10)) -gt 8 ]]
  then
    gay $TEXT
  else
    local VERSION=$(ls -D /usr/local/Cellar/cowsay)
    local COW=$(ls -1 /usr/local/Cellar/cowsay/$VERSION/share/cows | grep .cow | shuf -n 1)
    cowsay -f $COW "$TEXT" | lolcat
  fi
}

cm() {
  local COLOURS=(green red blue white yellow cyan magenta black)
  local COLOUR=${COLOURS[$RANDOM % ${#COLOURS[@]} + 1]}
  cmatrix -ab -u 3 -C $COLOUR "$@"
}

alias fish='asciiquarium'

alias weather='curl https://wttr.in\?format\=4'
alias ipinfo='curl https://ipinfo.io'
