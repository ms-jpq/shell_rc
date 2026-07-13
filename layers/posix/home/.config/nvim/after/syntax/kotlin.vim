syntax match ktImport "\<import\>" conceal cchar=↓

syntax match ktCommentEdge '^\s*\zs//' containedin=ktLineComment conceal cchar=┃
