syntax match pyImport "\<import\>" conceal cchar=↓
syntax match pyFrom "\%(yield\_s\+\)\@<!\<from\>" conceal cchar=→

syntax match pyCommentEdge '^\s*\zs#' containedin=pythonComment conceal cchar=┃
