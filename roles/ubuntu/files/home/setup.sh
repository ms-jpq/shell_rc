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
  build-essential
  curl
  libbz2-dev
  libffi-dev
  liblzma-dev
  libncurses5-dev
  libreadline-dev
  libsqlite3-dev
  libssl-dev
  libxml2-dev
  libxmlsec1-dev
  llvm
  make
  tk-dev
  wget
  xz-utils
  zlib1g-dev
)
apt-install "${PYTHON_DEPS[@]}"
asdf-install --global -- python


mkdir --parent -- "$XDG_DATA_HOME/gnupg"
NODEJS_CHECK_SIGNATURES=no asdf-install --global -- nodejs


asdf-install --global -- rust


asdf-install --global -- golang


RUBY_DEPS=(
 libssl-dev
)
apt-install "${RUBY_DEPS[@]}"
asdf-install --global -- ruby


#PHP_DEPS=(
#  autoconf
#  bison
#  libcurl4-openssl-dev
#  libgd-dev
#  libonig-dev
#  libzip-dev
#  re2c
#)
#apt-install "${PHP_DEPS[@]}"
#asdf-install --global -- php


#R_DEPS=(
#  build-essential
#  gfortran
#  libbz2-1.0 
#  libbz2-dev
#  libbz2-dev 
#  libcurl3-dev
#  liblzma-dev
#  liblzma-dev 
#  liblzma5 
#  libpcre2-dev
#  libreadline-dev 
#  xorg-dev 
#)
#R_OPTS=(
#  --enable-R-shlib
#  --with-cairo
#)
#apt-install "${R_DEPS[@]}"
#R_EXTRA_CONFIGURE_OPTIONS="${R_OPTS[*]}" asdf-install --global -- R

