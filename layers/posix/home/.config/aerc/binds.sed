#!/usr/bin/env -S -- sed -E -f

/d = :choose/d
/a = :archive/d
/A = :unmark/d
/A = :archive/d

/D = :delete/ {
  i\
D = :move 已删除邮件<Enter>
  d
}

/\[messages\]/ {
  a\
<C-r> = :connect<Enter>

  a\
w = :read -t<Enter>

  a\
{ = :prev 5<Enter>

  a\
} = :next 5<Enter>
}

/\[messages\]|\[view\]/ {
  a\
E = :envelope<Enter>

  a\
F = :forward -A<Enter>

  a\
RR = :reply<Enter>

  a\
RQ = :reply -q<Enter>
}
