silent! syntax clear ConcealNE

syntax match phpReq '^\s*\zs\<include\>' conceal cchar=↓
syntax match phpReq '^\s*\zs\<require\>' conceal cchar=↓

syntax match phpCommentEdge '^\s*\zs#' conceal cchar=│
syntax match phpCommentEdgeSlash '^\s*\zs//' conceal cchar=│

syntax match phpBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match phpBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match phpBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
