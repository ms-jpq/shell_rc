syntax match swiftImport "\<import\>" conceal cchar=↓

syntax match swiftFunc "\<func\>" conceal cchar=𝐟

syntax match swiftCommentEdge '^\s*\zs//' containedin=swiftLineComment conceal cchar=┃
