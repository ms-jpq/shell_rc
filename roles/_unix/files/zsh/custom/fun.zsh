#################### ########## ####################
#################### Fun Region ####################
#################### ########## ####################

alias gay='echo Fully Automated Luxury Gay Space Communism | figlet | lolcat'

cow() {
  local TEXT="'$*'"
  if [[ $((RANDOM % 10)) -gt 8 ]]
  then
    figlet "$TEXT" | lolcat
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
