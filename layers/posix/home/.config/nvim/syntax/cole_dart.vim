syntax match dartImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match dartCommentEdge '^\s*\zs//' conceal cchar=│

syntax match dartBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match dartBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match dartBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
