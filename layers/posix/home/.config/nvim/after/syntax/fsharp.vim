syntax match fsOpen "\<open\>" conceal cchar=↓

syntax match fsCommentEdge '^\s*\zs//' containedin=fsLineComment conceal cchar=┃
