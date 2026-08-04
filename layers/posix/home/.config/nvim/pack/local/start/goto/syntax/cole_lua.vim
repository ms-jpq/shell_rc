syntax match luaShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match luaShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match luaReq '\<require\ze\s*[(''"[]' conceal cchar=←

syntax match luaDo "\s\zs\<then\>$" conceal cchar=⌈
syntax match luaDo "\s\zs\<do\>$" conceal cchar=⌈
syntax match luaEnd "^\s*\zs\<end\>" conceal cchar=⌋

syntax match luaCommentEdge '^\s*\zs--' conceal cchar=│
