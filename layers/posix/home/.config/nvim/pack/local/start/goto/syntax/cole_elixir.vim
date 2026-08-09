syntax match elixirShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match elixirShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match elixirImport '^\s*\zs\<import\>' conceal cchar=←

syntax match elixirDo  "\s\zs\<do\>$" conceal cchar=⌈
syntax match elixirEnd "^\s*\zs\<end\>" conceal cchar=⌋

syntax match elixirCommentEdge '^\s*\zs#\ze!\@!' conceal cchar=│
syntax match elixirReplResponse '^\s*\zs#\s*|' conceal cchar=┇
