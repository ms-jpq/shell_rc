#!/usr/bin/env bash

set -eux
set -o pipefail


PATH="$PATH:/root/.config/zsh/rc/paths/bin"


PYTHON_DEPS=(
  make
  build-essential
  libssl-dev
  zlib1g-dev
  libbz2-dev
  libreadline-dev
  libsqlite3-dev
  wget
  curl
  llvm
  libncurses5-dev
  xz-utils
  tk-dev
  libxml2-dev
  libxmlsec1-dev
  libffi-dev
  liblzma-dev
)
DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y "${PYTHON_DEPS[@]}"
asdf-inst python

NODEJS_CHECK_SIGNATURES=no asdf-inst nodejs

asdf-inst golang
asdf-inst rust
