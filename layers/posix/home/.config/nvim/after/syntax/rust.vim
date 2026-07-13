syntax match rustUse "\<use\>" conceal cchar=↓

syntax match rustCommentEdge '^\s*\zs//' containedin=rustCommentLine conceal cchar=│

syntax match rustBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' containedin=rustCommentBlock conceal cchar=│

syntax match rustBlockCommentOpen '^\s*\zs\/\*' containedin=rustCommentBlock conceal cchar=┌
syntax match rustBlockCommentClose '^\s*\zs\*\/' containedin=rustCommentBlock conceal cchar=└
