syntax match awkShebangHash '\%1l^#\ze!' conceal cchar=⌘
syntax match awkShebangBang '\%1l\(^#\)\@<=!/usr/bin/env\ze\%(\s\|$\)' conceal cchar=‼

syntax match awkCommentEdge '^\s*\zs#\ze!\@!' conceal cchar=│
