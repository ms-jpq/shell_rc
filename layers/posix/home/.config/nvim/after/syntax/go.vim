syntax match goImport "\<import\>" conceal cchar=↓

syntax match goFunc "\<func\>" conceal cchar=ƒ

syntax match goCommentEdge '^\s*\zs//' containedin=goComment conceal cchar=┃
