syntax match rShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match rShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match rReq '^\s*\zs\<require\>' conceal cchar=↓

syntax match rCommentEdge '^\s*\zs#\ze!\@!' conceal cchar=│
