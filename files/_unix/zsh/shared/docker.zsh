#################### ############# ####################
#################### Docker Region ####################
#################### ############# ####################

dm() {
  if [ "$#" -eq 0 ]
  then
    export DOCKER_HOST='unix:///var/run/docker.sock'
  else
    export DOCKER_HOST="tcp://$1:${2:-2375}"
  fi
  printf '%s\n' "DOCKER_HOST=$DOCKER_HOST"
}

alias dun='docker rm --force $(docker ps -aq)'
alias dprune='docker system prune --all --volumes --force'

alias doc='docker-compose'
alias docup='doc up -d --build'
alias docuprm='docup --remove-orphans'

alias dex='docker exec -it'

alias dlog='docker logs -f'

alias dr='docker run -it --rm'
alias dre='dr --entrypoint'
alias drw='dr -w /workdir -v "$PWD":/workdir'
alias drs='dr -v /var/run/docker.sock:/var/run/docker.sock'

drx() {
  xhost + 127.0.0.1
  dr -e DISPLAY=host.docker.internal:0 -v /tmp/.X11-unix:/tmp/.X11-unix "$@"
}


#################### ################### ####################
#################### Docker Swarm Region ####################
#################### ################### ####################

alias dn='docker node'
alias dni='dn inspect --pretty'

alias dsd='docker stack deploy -c'

alias dsps='ds ps --no-trunc'

alias dsi='ds inspect --pretty'
alias dslog='docker service logs -f'


#################### ##################### ####################
#################### Applied Docker Region ####################
#################### ##################### ####################

alias dlz='drs --name=lazy_docker -v "$XDG_CONFIG_HOME/lazydocker":/.config/jesseduffield/lazydocker lazyteam/lazydocker'

alias k9='dr --name=k9s -v "$HOME/.kube":/root/.kube derailed/k9s'

alias ctop='drs --name=ctop quay.io/vektorlab/ctop -i -scale-cpu'
