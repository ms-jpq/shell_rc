syntax match dartShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match dartShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match dartImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match dartCommentEdge  '^\s*\zs//' conceal cchar=│
syntax match dartReplResponse '\%(^\s*//\s*\)\@<=|\ze\%(\s\|$)' conceal cchar=┇

syntax match dartBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match dartBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match dartBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
