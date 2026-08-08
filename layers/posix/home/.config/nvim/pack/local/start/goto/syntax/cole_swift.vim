syntax match swiftShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match swiftShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match swiftImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match swiftCommentEdge  '^\s*\zs//' conceal cchar=│
syntax match swiftReplResponse '\%(^\s*//\s*\)\@<=|\ze\s' conceal cchar=┇

syntax match swiftBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match swiftBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match swiftBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
