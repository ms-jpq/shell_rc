syntax match scalaImport "\<import\>" conceal cchar=↓

syntax match scalaCommentEdge '^\s*\zs//' containedin=scalaTrailingComment conceal cchar=┃
