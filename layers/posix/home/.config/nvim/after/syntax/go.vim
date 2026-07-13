syntax match goImport "\<import\>" conceal cchar=↓

syntax match goCommentEdge '^\s*\zs//' containedin=goComment conceal cchar=│

syntax match goBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' containedin=goComment conceal cchar=│

syntax match goBlockCommentOpen '^\s*\zs\/\*' containedin=goComment conceal cchar=┌
syntax match goBlockCommentClose '^\s*\zs\*\/' containedin=goComment conceal cchar=└
