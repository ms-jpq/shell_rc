syntax match awkFunc "\<function\>" conceal cchar=𝐟

syntax match awkCommentEdge '^\s*\zs#' containedin=awkComment conceal cchar=┃
