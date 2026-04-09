#!/usr/bin/env -S -- awk -f

BEGIN {
  OSC8 = "\033]8;;"
  ST = "\033\\"
  CLS = "\033[0m"
  BOLD = "\033[1m"
  RED = "\033[31m"
  GREEN = "\033[0;32m"
  YELLOW = "\033[0;33m"
  PURPLE = "\033[0;35m"
  PARSING_REFS = 1
  command = "pr --omit-header --omit-pagination --indent " ENVIRON["IDENT"] " --width " ENVIRON["WIDTH"]
}

PARSING_REFS && NF == 2 && $1 ~ /^\[[0-9]+\]$/ {
  N = $1
  gsub(/[\[\]]/, "", N)
  REFS[N] = $2
  $1 = _LINKIFY($1, $2)
  $2 = _COLOURIZE($2)
  # print
  next
}

PARSING_REFS && /^[[:space:]]*$/ {
  print
  next
}

{
  PARSING_REFS = 0
  for (N in REFS) {
    gsub("\\[" N "\\]", _LINKIFY("[" N "]", REFS[N]) " ", $0)
  }
  print | command
}

function _COLOURIZE(LINK)
{
  if (LINK ~ /^file:/) {
    return (YELLOW LINK CLS)
  }
  if (LINK ~ /^mailto:/) {
    return (PURPLE LINK CLS)
  }
  return (GREEN LINK CLS)
}

function _LINKIFY(TEXT, LINK)
{
  return (BOLD RED (OSC8 LINK ST TEXT OSC8 ST) CLS)
}
