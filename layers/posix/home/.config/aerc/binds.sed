#!/usr/bin/env -S -- sed -E -f

/\[messages\]/ {
  a<C-r> = :connect<Enter>
}

/d = :choose/d
/D = :delete/ {
  iD = :move Trash<Enter>
  d
}
