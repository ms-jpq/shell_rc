syntax match awkFunc "\<function\>" conceal cchar=ƒ

syntax match awkRet "\<return\>" conceal cchar=⏎

syntax match awkCommentEdge '^\s*\zs#' containedin=awkComment conceal cchar=┃
