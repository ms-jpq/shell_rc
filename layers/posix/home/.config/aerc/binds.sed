#!/usr/bin/env -S -- sed -E -f

/\[messages\]/ {
  a\
<C-r> = :connect<Enter>
}

/d = :choose/d
/D = :delete/ {
  i\
D = :move 已删除邮件<Enter>
  d
}
