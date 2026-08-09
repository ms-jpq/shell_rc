syntax match luaShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match luaShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match luaReq '\<require\>\ze\%([ \t]\+\|[ \t]*(\s*\)\%("[^"]*"\|\[\[.\{-}\]\]\)\%([ \t]*\|[ \t]*)\)\%(\-\-.*\)\?$' conceal cchar=←

syntax match luaDo "\%(^\|[ \t]\)\zs\<then\>$" conceal cchar=⌈
syntax match luaDo "\%(^\|[ \t]\)\zs\<do\>$" conceal cchar=⌈
syntax match luaEnd "^[ \t]*\zs\<end\>" conceal cchar=⌋

syntax match luaCommentEdge  '^\s*\zs--' conceal cchar=│
syntax match luaReplResponse '^\s*\zs--\s*|' conceal cchar=┇
