syntax clear ConcealNE

syntax match jsFrom "\.\@<!\<from\>" conceal cchar=←
syntax match jsReq "\<require\>" conceal cchar=←
syntax match jsImport "\<import\>" conceal cchar=↓

syntax match jsFunc "\<function\>" conceal cchar=ƒ

syntax match jsCommentEdge '^\s*\zs//' containedin=javaScriptLineComment conceal cchar=┃
