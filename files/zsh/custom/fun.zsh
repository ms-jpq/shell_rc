#################### ########## ####################
#################### Fun Region ####################
#################### ########## ####################

__gay() {
  local TEXT="'$*'"
  if [[ "$#" -eq 0 ]]
  then
    local TEXT="Fully Automated Luxury Gay Space Communism"
  fi
  figlet "$TEXT" | lolcat -a -d 1 -s 250
}
alias gay=' __gay'

__cow() {
  local TEXT="'$*'"
  if [[ $((RANDOM % 10)) -gt 8 ]]
  then
    gay $TEXT
  else
    local VERSION=$(ls -D /usr/local/Cellar/cowsay)
    local COW=$(ls -1 /usr/local/Cellar/cowsay/$VERSION/share/cows | grep .cow | shuf -n 1)
    cowsay -f $COW "$TEXT" | lolcat -a -d 1 -s 250
  fi
}
alias cow=' __cow'

__cm() {
  local COLOURS=(green red blue white yellow cyan magenta black)
  local COLOUR=${COLOURS[$RANDOM % ${#COLOURS[@]} + 1]}
  cmatrix -ab -u 3 -C $COLOUR "$@"
}
alias cm=' __cm'

alias fish=' asciiquarium'

alias weather=' curl https://wttr.in\?T'
alias ipinfo=' curl https://ipinfo.io'
