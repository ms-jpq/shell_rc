syntax match javaImport "\<import\>" conceal cchar=↓

syntax match javaCommentEdge '^\s*\zs//' containedin=javaLineComment conceal cchar=│

syntax match javaBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' containedin=javaComment conceal cchar=│

syntax match javaBlockCommentOpen '^\s*\zs\/\*' containedin=javaComment conceal cchar=┌
syntax match javaBlockCommentClose '^\s*\zs\*\/' containedin=javaComment conceal cchar=└
