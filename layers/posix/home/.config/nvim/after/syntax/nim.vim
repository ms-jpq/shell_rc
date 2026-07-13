syntax match nimImport "\<import\>" conceal cchar=↓

syntax match nimRet "\<return\>" conceal cchar=⏎

syntax match nimCommentEdge '^\s*\zs#' containedin=nimLineComment conceal cchar=┃
