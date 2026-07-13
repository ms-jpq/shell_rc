syntax match rustUse "\<use\>" conceal cchar=↓

syntax match rustFn "\<fn\>" conceal cchar=𝐟

syntax match rustCommentEdge '^\s*\zs//' containedin=rustCommentLine conceal cchar=┃
