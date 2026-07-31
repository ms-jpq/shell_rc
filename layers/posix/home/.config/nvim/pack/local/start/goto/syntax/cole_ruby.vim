syntax match rubyShebangHash '\%1l^#\ze!' conceal cchar=⌘
syntax match rubyShebangBang '\%1l\(^#\)\@<=!/usr/bin/env\ze\%(\s\|$\)' conceal cchar=‼

syntax match rubyReq '^\s*\zs\<require\>' conceal cchar=←

syntax match rubyEnd "^\s*\zs\<end\>" conceal cchar=⌋

syntax match rubyCommentEdge '^\s*\zs#\ze!\@!' conceal cchar=│
