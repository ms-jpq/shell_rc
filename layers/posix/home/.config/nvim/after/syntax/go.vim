syntax match goImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match goCommentEdge '^\s*\zs//' conceal cchar=│

syntax match goBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match goBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match goBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
