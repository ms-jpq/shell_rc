#!/usr/bin/env bash

#################### ########### ####################
#################### Path Region ####################
#################### ########### ####################

_paths=(
  '/opt/homebrew/bin'
  '/opt/homebrew/sbin'
  '/opt/homebrew/opt/bc/bin'
  '/opt/homebrew/opt/coreutils/libexec/gnubin'
  '/opt/homebrew/opt/curl/bin'
  '/opt/homebrew/opt/findutils/libexec/gnubin'
  '/opt/homebrew/opt/gnu-getopt/bin'
  '/opt/homebrew/opt/gnu-sed/libexec/gnubin'
  '/opt/homebrew/opt/gnu-tar/libexec/gnubin'
  '/opt/homebrew/opt/gnu-which/libexec/gnubin'
  '/opt/homebrew/opt/grep/libexec/gnubin'
  '/opt/homebrew/opt/icu4c/bin'
  '/opt/homebrew/opt/icu4c/sbin'
  '/opt/homebrew/opt/lsof/bin'
  '/opt/homebrew/opt/ncurses/bin'
  '/opt/homebrew/opt/openssl/bin'
)
pathprepend "${_paths[@]}"
unset _paths
