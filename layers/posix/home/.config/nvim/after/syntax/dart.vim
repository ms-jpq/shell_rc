syntax match dartImport "\<import\>" conceal cchar=↓

syntax match dartCommentEdge '^\s*\zs//' containedin=dartLineComment conceal cchar=┃
