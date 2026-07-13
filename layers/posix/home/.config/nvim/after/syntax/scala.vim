syntax match scalaImport "\<import\>" conceal cchar=↓

syntax match scalaRet "\<return\>" conceal cchar=⏎

syntax match scalaCommentEdge '^\s*\zs//' containedin=scalaTrailingComment conceal cchar=┃
