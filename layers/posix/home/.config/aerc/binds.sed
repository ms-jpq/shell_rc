#!/usr/bin/env -S -- sed -E -f

/\[messages\]/ {
  a\
<C-r> = :connect<Enter>

  a\
w = :read -t<Enter>

  a\
{ = :prev 5<Enter>

  a\
} = :next 5<Enter>

  a\
E = :envelope<Enter>

  a\
F = :forward -A<Enter>
}

/\[view\]/ {
  a\
E = :envelope<Enter>
}

/d = :choose/d
/D = :delete/ {
  i\
D = :move 已删除邮件<Enter>
  d
}

/a = :archive/d
/A = :unmark/d
/A = :archive/d
