#!/usr/bin/env -S -- awk -f

BEGIN {
  OSC8 = "\033]8;;"
  ST = "\033\\"
  CLS = "\033[0m"
  BOLD = "\033[1m"
  RED = "\033[31m"
  GREEN = "\033[0;32m"
  YELLOW = "\033[0;33m"
  PARSING_REFS = 1
}

PARSING_REFS {
  if (NF == 2 && $1 ~ /^\[[0-9]+\]$/) {
    N = $1
    gsub(/[\[\]]/, "", N)
    REFS[N] = $2
    $1 = _LINKIFY($1, $2) CLS
    $2 = _COLOURIZE($2)
  } else if (! /^[[:space:]]*$/) {
    PARSING_REFS = 0
  }
}

! PARSING_REFS {
  for (N in REFS) {
    gsub("\\[" N "\\]", _LINKIFY("[" N "]", REFS[N]) " ", $0)
  }
}

{
  print
}

function _COLOURIZE(LINK)
{
  if (LINK ~ /^mailto:/) {
    return (YELLOW LINK CLS)
  }
  return (GREEN LINK CLS)
}

function _LINKIFY(TEXT, LINK)
{
  return (BOLD RED (OSC8 LINK ST TEXT OSC8 ST) CLS)
}
