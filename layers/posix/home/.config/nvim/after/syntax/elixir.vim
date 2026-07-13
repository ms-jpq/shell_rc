syntax match elixirImport '^\s*\zs\<import\>' conceal cchar=←

syntax match elixirDo "\s\zs\<do\>$" conceal cchar=⌈
syntax match elixirEnd "^\s*\zs\<end\>" conceal cchar=⌋

syntax match elixirCommentEdge '^\s*\zs#' conceal cchar=│
