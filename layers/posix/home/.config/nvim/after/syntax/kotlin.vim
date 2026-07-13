syntax match ktImport "\<import\>" conceal cchar=↓

syntax match ktRet "\<return\>" conceal cchar=⏎

syntax match ktCommentEdge '^\s*\zs//' containedin=ktLineComment conceal cchar=┃
