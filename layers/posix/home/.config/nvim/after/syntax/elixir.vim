syntax match elixirImport "\<import\>" conceal cchar=↓

syntax match elixirDo "\<do\>" conceal cchar=⌈
syntax match elixirEnd "\<end\>" conceal cchar=⌋

syntax match elixirCommentEdge '^\s*\zs#' containedin=elixirComment conceal cchar=│
