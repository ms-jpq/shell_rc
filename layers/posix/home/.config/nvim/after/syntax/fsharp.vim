syntax match fsOpen "\<open\>" conceal cchar=↓

syntax match fsFun "\<fun\>" conceal cchar=λ

syntax match fsRet "\<return\>" conceal cchar=⏎

syntax match fsCommentEdge '^\s*\zs//' containedin=fsLineComment conceal cchar=┃
