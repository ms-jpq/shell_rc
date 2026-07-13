syntax match scalaImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match scalaCommentEdge '^\s*\zs//' conceal cchar=│

syntax match scalaBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match scalaBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match scalaBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
