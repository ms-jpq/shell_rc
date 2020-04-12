#################### ########## ####################
#################### Fun Region ####################
#################### ########## ####################

alias shark='sudo termshark'

gay() {
  local TEXT=${*:-"Fully Automated Luxury Gay Space Communism"}
  figlet "$TEXT" | lolcat -a -d 1 -s 1000
}


cow() {
  local TEXT="$*"
  if [[ $((RANDOM % 10)) -gt 8 ]]
  then
    gay "$TEXT"
  else
    local COWS="$(echo "/usr/local/Cellar/cowsay/"**/*".cow")"
    local COW="$(echo "$COWS" | tr " " "\n" | shuf -n 1)"
    cowsay -f "$COW" "$TEXT" | lolcat -a -d 1 -s 1000
  fi
}

cm() {
  local COLOURS=(green red blue white yellow cyan magenta black)
  local COLOUR=${COLOURS[$RANDOM % ${#COLOURS[@]} + 1]}
  cmatrix -ab -u 3 -C "$COLOUR" "$@"
}

alias fish='asciiquarium'

alias weather='curl -H "Accept-Language: zh" https://wttr.in\?T'
alias ipinfo='curl https://ipinfo.io'

alias foxd='dr browsh/browsh'

alias icat='catimg'
