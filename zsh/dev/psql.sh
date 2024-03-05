#!/usr/bin/env -S -- bash

# TODO: PSPG_CONF
_pspg=(
  # --direct-color
  --bold-cursor
  --bold-labels
  --double-header
  --force-uniborder
  --menu-always
  --on-sigint-exit
  --reprint-on-exit
  --style 16
)
printf -v PSPG -- '%q ' "${_pspg[@]}"
export -- PSPG PSQL_PAGER=pspg
