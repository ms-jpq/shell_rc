syntax match javaImport "\<import\>" conceal cchar=↓

syntax match javaCommentEdge '^\s*\zs//' containedin=javaLineComment conceal cchar=┃
