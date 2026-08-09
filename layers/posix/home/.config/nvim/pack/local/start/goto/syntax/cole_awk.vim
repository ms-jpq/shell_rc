syntax match awkShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match awkShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match awkCommentEdge  '^\s*\zs#\ze!\@!' conceal cchar=│
syntax match awkReplResponse '\%(^\s*#\s*\)\@<=|\ze\%(\s\|$)' conceal cchar=┇
