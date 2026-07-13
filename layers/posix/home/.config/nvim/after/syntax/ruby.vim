syntax match rubyReq '^\s*\zs\<require\>' conceal cchar=↓

syntax match rubyDo "\.\@<!\<do\>" conceal cchar=⌈
syntax match rubyEnd "\.\@<!\<end\>" conceal cchar=⌋

syntax match rubyCommentEdge '^\s*\zs#' conceal cchar=│
