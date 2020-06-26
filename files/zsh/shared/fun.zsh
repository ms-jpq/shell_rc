#################### ########## ####################
#################### Fun Region ####################
#################### ########## ####################

alias shark='sudo termshark'

alias fish='asciiquarium'

alias ipinfo='curl https://ipinfo.io'

alias foxd='dr browsh/browsh'

alias icat='catimg'


gay() {
  local TEXT=${*:-"Fully Automated Luxury Gay Space Communism"}
  figlet "$TEXT" | lolcat -a -d 1 -s 1000
}

