syntax match pyImport "\<import\>" conceal cchar=↓
syntax match pyFrom "\%(yield\_s\+\)\@<!\<from\>" conceal cchar=→

syntax match pyDef "\<def\>" conceal cchar=ƒ
syntax match pyLambda "\<lambda\>" conceal cchar=λ

syntax match pyCommentEdge '^\s*\zs#' containedin=pythonComment conceal cchar=┃
