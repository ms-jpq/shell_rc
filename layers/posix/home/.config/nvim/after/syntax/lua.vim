syntax match luaReq "\<require\>" conceal cchar=←

syntax match luaDo "\<then\>" conceal cchar=⌈
syntax match luaDo "\.\@<!\<do\>" conceal cchar=⌈
syntax match luaEnd "\.\@<!\<end\>" conceal cchar=⌋

syntax match luaCommentEdge '^\s*\zs--' containedin=luaComment conceal cchar=┃
