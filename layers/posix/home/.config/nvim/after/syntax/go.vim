syntax match goImport "\<import\>" conceal cchar=↓

syntax match goCommentEdge '^\s*\zs//' containedin=goComment conceal cchar=┃
