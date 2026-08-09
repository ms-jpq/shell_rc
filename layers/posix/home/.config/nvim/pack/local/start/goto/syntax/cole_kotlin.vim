syntax match ktShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match ktShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match ktImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match ktCommentEdge  '^\s*\zs//' conceal cchar=│
syntax match ktReplResponse '^\s*\zs//\s*|' conceal cchar=┇

syntax match ktBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match ktBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match ktBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
