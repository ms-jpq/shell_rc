syntax clear ConcealNE

syntax match phpReq "\<include\>" conceal cchar=↓
syntax match phpReq "\<require\>" conceal cchar=↓

syntax match phpCommentEdge '^\s*\zs#' containedin=phpComment conceal cchar=│
syntax match phpCommentEdgeSlash '^\s*\zs//' containedin=phpComment conceal cchar=│

syntax match phpBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' containedin=phpComment conceal cchar=│

syntax match phpBlockCommentOpen '^\s*\zs\/\*' containedin=phpComment conceal cchar=┌
syntax match phpBlockCommentClose '^\s*\zs\*\/' containedin=phpComment conceal cchar=└
