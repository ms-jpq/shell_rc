syntax match rReq "\<require\>" conceal cchar=↓

syntax match rCommentEdge '^\s*\zs#' containedin=rComment conceal cchar=│
