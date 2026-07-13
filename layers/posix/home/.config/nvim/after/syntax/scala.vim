syntax match scalaImport "\<import\>" conceal cchar=↓

syntax match scalaCommentEdge '^\s*\zs//' containedin=scalaTrailingComment conceal cchar=│

syntax match scalaBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' containedin=scalaMultilineComment conceal cchar=│

syntax match scalaBlockCommentOpen '^\s*\zs\/\*' containedin=scalaMultilineComment conceal cchar=┌
syntax match scalaBlockCommentClose '^\s*\zs\*\/' containedin=scalaMultilineComment conceal cchar=└
