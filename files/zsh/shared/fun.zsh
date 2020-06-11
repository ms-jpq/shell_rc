#################### ########## ####################
#################### Fun Region ####################
#################### ########## ####################

alias shark='sudo termshark'

alias fish='asciiquarium'

alias weather='curl -H "Accept-Language: zh" https://wttr.in\?T'
alias ipinfo='curl https://ipinfo.io'

alias foxd='dr browsh/browsh'

alias icat='catimg'


gay() {
  local TEXT=${*:-"Fully Automated Luxury Gay Space Communism"}
  figlet "$TEXT" | lolcat -a -d 1 -s 1000
}

cm() {
  local COLOURS=(green red blue white yellow cyan magenta black)
  local COLOUR="${COLOURS[$(($RANDOM % ${#COLOURS[@]} + 1))]}"
  cmatrix -ab -u 3 -C "$COLOUR" "$@"
}

