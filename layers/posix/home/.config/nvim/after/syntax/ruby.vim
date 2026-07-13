syntax match rubyReq "\<require\>" conceal cchar=↓

syntax match rubyDef "\<def\>" conceal cchar=𝐟
syntax match rubyLambda "\<lambda\>" conceal cchar=λ

syntax match rubyDo "\.\@<!\<do\>" conceal cchar=⌈
syntax match rubyEnd "\.\@<!\<end\>" conceal cchar=⌋

syntax match rubyCommentEdge '^\s*\zs#' containedin=rubyComment conceal cchar=┃
