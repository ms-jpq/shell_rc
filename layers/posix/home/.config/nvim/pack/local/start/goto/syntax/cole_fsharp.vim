syntax match fsShebangHash '\%1l^#\ze!' conceal cchar=⌘
syntax match fsShebangBang '\%1l\(^#\)\@<=!/usr/bin/env\ze\%(\s\|$\)' conceal cchar=‼

syntax match fsOpen '^\s*\zs\<open\>' conceal cchar=↓

syntax match fsCommentEdge '^\s*\zs//' conceal cchar=│
