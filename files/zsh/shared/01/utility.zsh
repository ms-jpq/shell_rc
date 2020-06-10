#################### ############## ####################
#################### Utility Region ####################
#################### ############## ####################

alias rsy='rsync -ah --no-o --no-g --info progress2'


proxy() {
  if [[ "$#" -eq 0 ]]
  then
    unset http_proxy
    unset https_proxy
  else
    export http_proxy="http://${2:-localhost}:$1"
    export https_proxy="http://${2:-localhost}:$1"
  fi
  echo "http_proxy =$http_proxy"
  echo "https_proxy=$https_proxy"
}

