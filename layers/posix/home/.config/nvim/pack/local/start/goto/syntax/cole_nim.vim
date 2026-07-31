syntax match nimShebangHash '\%1l^#\ze!' conceal cchar=⌘
syntax match nimShebangBang '\%1l\(^#\)\@<=!/usr/bin/env\ze\%(\s\|$\)' conceal cchar=‼

syntax match nimImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match nimCommentEdge '^\s*\zs#' conceal cchar=│
