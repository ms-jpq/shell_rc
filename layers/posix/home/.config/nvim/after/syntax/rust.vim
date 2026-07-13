syntax match rustUse "\<use\>" conceal cchar=↓

syntax match rustCommentEdge '^\s*\zs//' containedin=rustCommentLine conceal cchar=┃
