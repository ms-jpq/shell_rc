syntax match awkFunc "\<function\>" conceal cchar=ƒ

syntax match awkCommentEdge '^\s*\zs#' containedin=awkComment conceal cchar=┃
