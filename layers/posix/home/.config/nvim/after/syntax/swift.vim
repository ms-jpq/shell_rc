syntax match swiftImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match swiftCommentEdge '^\s*\zs//' conceal cchar=│

syntax match swiftBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match swiftBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match swiftBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
