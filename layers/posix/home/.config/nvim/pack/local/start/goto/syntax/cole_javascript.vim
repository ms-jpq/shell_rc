syntax match jsShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match jsShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match jsFrom "\.\@<!\<from\>" conceal cchar=←
syntax match jsReq "\<require\ze\s*(" conceal cchar=←
syntax match jsImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match jsCommentEdge  '^\s*\zs//' conceal cchar=│
syntax match jsReplResponse '\%(^\s*//\s*\)\@<=|\ze\s' conceal cchar=┇

syntax match jsBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match jsBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match jsBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
