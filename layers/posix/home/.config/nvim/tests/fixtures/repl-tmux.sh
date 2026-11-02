#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SEP=$'\037'
case "$3" in
display-message)
  printf -- '%s' '@window'
  ;;
list-panes)
  PANES=(
    "main${SEP}0${SEP}0${SEP}@window${SEP}@caller${SEP}1${SEP}caller${SEP}/caller"
    "main${SEP}0${SEP}1${SEP}@window${SEP}@locked${SEP}0${SEP}locked${SEP}/locked"
    "main${SEP}0${SEP}2${SEP}@window${SEP}@outside${SEP}0${SEP}outside${SEP}/outside"
  )
  printf -- '%s\n' "${PANES[@]}"
  ;;
*)
  set -x
  exit 2
  ;;
esac
