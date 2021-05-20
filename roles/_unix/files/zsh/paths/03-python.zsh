#!/usr/bin/env bash

#################### ############# ####################
#################### Python Region ####################
#################### ############# ####################

export MYPY_CACHE_DIR="$XDG_CACHE_HOME/mypy"

venv() {
  source <(cmd venv "$@")
}
