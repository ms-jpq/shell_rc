syntax match ktImport "\<import\>" conceal cchar=↓

syntax match ktCommentEdge '^\s*\zs//' containedin=ktLineComment conceal cchar=│

syntax match ktBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' containedin=ktComment conceal cchar=│

syntax match ktBlockCommentOpen '^\s*\zs\/\*' containedin=ktComment conceal cchar=┌
syntax match ktBlockCommentClose '^\s*\zs\*\/' containedin=ktComment conceal cchar=└
