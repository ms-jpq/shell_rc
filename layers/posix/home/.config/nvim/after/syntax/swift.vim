syntax match swiftImport "\<import\>" conceal cchar=↓

syntax match swiftFunc "\<func\>" conceal cchar=ƒ

syntax match swiftRet "\<return\>" conceal cchar=⏎

syntax match swiftCommentEdge '^\s*\zs//' containedin=swiftLineComment conceal cchar=┃
