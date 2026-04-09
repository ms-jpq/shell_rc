#!/usr/bin/env -S -- awk -f

BEGIN {
  PARSING_REFS = 1
}

PARSING_REFS {
  if (/^[[:space:]]*$/) {
    next
  }
  if ($1 ~ /^\[[0-9]+\]$/) {
    N = $1
    gsub(/[\[\]]/, "", N)
    REFS[N] = $2
    next
  }
  PARSING_REFS = 0
}

! PARSING_REFS {
  for (N in REFS) {
    gsub("\\[" N "\\]", "[" N "](" REFS[N] ")", $0)
  }
  print
}
