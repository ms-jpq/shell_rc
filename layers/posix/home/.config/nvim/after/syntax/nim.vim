syntax match nimImport "\<import\>" conceal cchar=↓

syntax match nimCommentEdge '^\s*\zs#' containedin=nimLineComment conceal cchar=┃
