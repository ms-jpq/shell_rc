syntax match rustUse "\<use\>" conceal cchar=↓

syntax match rustFn "\<fn\>" conceal cchar=ƒ

syntax match rustRet "\<return\>" conceal cchar=⏎

syntax match rustCommentEdge '^\s*\zs//' containedin=rustCommentLine conceal cchar=┃
