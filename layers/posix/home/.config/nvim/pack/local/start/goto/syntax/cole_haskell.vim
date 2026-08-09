syntax match hsShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match hsShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match hsImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match hsCommentEdge  '^\s*\zs--' conceal cchar=│
syntax match hsReplResponse '\%(^\s*--\s*\)\@<=|\ze\%(\s\|$)' conceal cchar=┇
