syntax match rReq "\<require\>" conceal cchar=↓

syntax match rFunc "\<function\>" conceal cchar=𝐟

syntax match rCommentEdge '^\s*\zs#' containedin=rComment conceal cchar=┃
