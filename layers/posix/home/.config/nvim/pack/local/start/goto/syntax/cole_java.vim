syntax match javaShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match javaShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match javaImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match javaCommentEdge  '^\s*\zs//' conceal cchar=│
syntax match javaReplResponse '^\s*\zs//\s*|\ze\%(\s\|$\)' conceal cchar=┇

syntax match javaBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match javaBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match javaBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
