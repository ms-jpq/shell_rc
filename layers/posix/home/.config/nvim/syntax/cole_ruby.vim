syntax match rubyReq '^\s*\zs\<require\>' conceal cchar=←

syntax match rubyEnd "^\s*\zs\<end\>" conceal cchar=⌋

syntax match rubyCommentEdge '^\s*\zs#' conceal cchar=│
