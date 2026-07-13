syntax match perlReq "\<require\>" conceal cchar=↓
syntax match perlUse "\<use\>" conceal cchar=↓

syntax match perlSub "\<sub\>" conceal cchar=ƒ

syntax match perlRet "\<return\>" conceal cchar=⏎

syntax match perlCommentEdge '^\s*\zs#' containedin=perlComment conceal cchar=┃
