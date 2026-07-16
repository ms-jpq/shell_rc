syntax match ktImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match ktCommentEdge '^\s*\zs//' conceal cchar=│

syntax match ktBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match ktBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match ktBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
