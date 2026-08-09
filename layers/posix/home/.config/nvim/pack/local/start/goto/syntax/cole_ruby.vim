syntax match rubyShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match rubyShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match rubyReq '^\s*\zs\<require\>' conceal cchar=←

syntax match rubyEnd "^\s*\zs\<end\>" conceal cchar=⌋

syntax match rubyCommentEdge  '^\s*\zs#\ze!\@!' conceal cchar=│
syntax match rubyReplResponse '^\s*\zs#\s*|' conceal cchar=┇
