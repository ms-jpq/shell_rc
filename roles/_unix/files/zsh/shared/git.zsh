#!/usr/bin/env bash

#################### ########## ####################
#################### Git Region ####################
#################### ########## ####################

export GIT_PAGER='delta'

alias lg='lazygit'


git-ssh() {
  source <(cmd git-ssh "$*")
}
