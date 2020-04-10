#################### ########### ####################
#################### Core Region ####################
#################### ########### ####################

# Safety
alias rm='rm -I'
alias mv='mv -i'
alias cp='cp -i'
# Safety

alias cls='clear'

alias c='clipcopy'
alias p='clippaste'

alias sudo='sudo -E '

alias ls='exa --group-directories-first --icons -hF'
alias l='ls -1'
alias ll='ls -lg'
alias tree='ls -T -L'

alias cat='bat'

alias hist='history'

alias trash='trash -v'

alias rsy='rsync -ah --no-o --no-g --info progress2'

alias gt='gotop -c lite'


ma() {
  man "$1" | col -b
}

alias srv='python3 -m http.server'

proxy() {
  if [ "$#" -eq 0 ]
  then
    unset http_proxy
    unset https_proxy
  else
    export http_proxy="http://${2:-localhost}:$1"
    export https_proxy="http://${2:-localhost}:$1"
  fi
  echo "http_proxy=$http_proxy"
  echo "https_proxy=$https_proxy"
}


extract() {
  local FILE="$1"

  case "$FILE" in
    *.tar.bz|*.tar.bz2|*.tbz|*.tbz2)
      tar xjvf "$FILE"
      ;;
    *.tar.gz|*.tgz)
      tar xzvf "$FILE"
      ;;
    *.tar.xz|*.txz)
      tar xJvf "$FILE"
      ;;
    *.zip)
      unzip "$FILE"
      ;;
    *.rar)
      unrar x "$FILE"
      ;;
    *.7z)
      7z x "$FILE"
      ;;
    *)
      echo "Unknown format :: $FILE"
      ;;
  esac
}
