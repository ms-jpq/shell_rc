syntax match fsOpen "\<open\>" conceal cchar=↓

syntax match fsFun "\<fun\>" conceal cchar=λ

syntax match fsCommentEdge '^\s*\zs//' containedin=fsLineComment conceal cchar=┃
