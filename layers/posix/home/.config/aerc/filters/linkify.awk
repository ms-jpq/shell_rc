#!/usr/bin/env -S -- awk -f

BEGIN {
  PARSING_REFS = 1
}

PARSING_REFS {
  if (NF == 2 && $1 ~ /^\[[0-9]+\]$/) {
    N = $1
    gsub(/[\[\]]/, "", N)
    REFS[N] = $2
  } else if (! /^[[:space:]]*$/) {
    PARSING_REFS = 0
  }
}

! PARSING_REFS {
  for (N in REFS) {
    gsub("\\[" N "\\]", "[" N "](" REFS[N] ")", $0)
  }
}

{
  print
}
