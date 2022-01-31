#!/usr/bin/env bash

set -eux
set -o pipefail


apt-install() {
  DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends --yes -- "$@"
}


##
##
##


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
apt-install "${PYTHON_DEPS[@]}"
asdf-install python


RUBY_DEPS=(
 libssl-dev
)
apt-install "${RUBY_DEPS[@]}"
asdf-install ruby


R_DEPS=(
  build-essential
  libcurl3-dev
  libreadline-dev 
  gfortran
  liblzma-dev 
  liblzma5 
  libbz2-1.0 
  libbz2-dev
  xorg-dev 
  libbz2-dev 
  liblzma-dev
  libpcre2-dev
  )
R_OPTS=(
  --enable-R-shlib
  --with-cairo
)
apt-install  "${R_DEPS[@]}"
R_EXTRA_CONFIGURE_OPTIONS="${R_OPTS[*]}" asdf-install R


mkdir --parent -- "$XDG_DATA_HOME/gnupg"
NODEJS_CHECK_SIGNATURES=no asdf-install nodejs


asdf-install rust

asdf-install golang
