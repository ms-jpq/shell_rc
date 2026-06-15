#!/usr/bin/env -S -- awk -f

BEGIN {
  OSC8 = "\033]8;;"
  ST = "\033\\"
  CLS = "\033[0m"
  BOLD = "\033[1m"
  RED = "\033[31m"
  GREEN = "\033[0;32m"
  YELLOW = "\033[0;33m"
  CYAN = "\033[0;36m"
  PURPLE = "\033[0;35m"
  PARSING_REFS = 1
  command = "pr --omit-header --omit-pagination --indent " ENVIRON["IDENT"] " --width " ENVIRON["WIDTH"]
}

PARSING_REFS && NF == 2 && $1 ~ /^\[[0-9]+\]$/ {
  N = $1
  gsub(/[\[\]]/, "", N)
  REFS[N] = $2
  $1 = _LINKIFY($1, $2)
  $2 = _COLOURIZE($2) $2 CLS
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
    $0 = _REPLACE($0, "[" N "]", _LINKIFY("[" N "]", REFS[N]) " ")
  }
  print | command
}

END {
  close(command)
}

function _COLOURIZE(LINK)
{
  if (LINK ~ /^file:/) {
    return PURPLE
  }
  if (LINK ~ /^tel:/) {
    return CYAN
  }
  if (LINK ~ /^mailto:/) {
    return YELLOW
  }
  return RED
}

function _LINKIFY(TEXT, LINK)
{
  return (BOLD _COLOURIZE(LINK) (OSC8 LINK ST TEXT OSC8 ST) CLS)
}

function _REPLACE(REST, FIND, REPL, L_OUT, L_POS)
{
  while ((L_POS = index(REST, FIND)) > 0) {
    L_OUT = L_OUT substr(REST, 1, L_POS - 1) REPL
    REST = substr(REST, L_POS + length(FIND))
  }
  return (L_OUT REST)
}
