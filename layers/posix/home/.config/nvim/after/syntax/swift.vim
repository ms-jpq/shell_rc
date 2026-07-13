syntax match swiftImport "\<import\>" conceal cchar=↓

syntax match swiftCommentEdge '^\s*\zs//' containedin=swiftLineComment conceal cchar=┃
