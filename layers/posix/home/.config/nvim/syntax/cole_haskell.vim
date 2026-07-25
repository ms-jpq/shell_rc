syntax match hsShebangHash '\%1l^#\ze!' conceal cchar=⌘
syntax match hsShebangBang '\%1l\(^#\)\@<=!/usr/bin/env\ze\%(\s\|$\)' conceal cchar=‼

syntax match hsImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match hsCommentEdge '^\s*\zs--' conceal cchar=│
