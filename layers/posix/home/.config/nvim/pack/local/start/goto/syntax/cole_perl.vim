syntax match perlShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match perlShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match perlReq '^\s*\zs\<require\>' conceal cchar=↓
syntax match perlUse '^\s*\zs\<use\>' conceal cchar=↓

syntax match perlCommentEdge  '^\s*\zs#\ze!\@!' conceal cchar=│
syntax match perlReplResponse '^\s*\zs#\s*|' conceal cchar=┇
