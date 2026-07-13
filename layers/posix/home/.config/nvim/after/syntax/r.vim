syntax match rReq "\<require\>" conceal cchar=↓

syntax match rFunc "\<function\>" conceal cchar=ƒ

syntax match rRet "\<return\>" conceal cchar=⏎

syntax match rCommentEdge '^\s*\zs#' containedin=rComment conceal cchar=┃
