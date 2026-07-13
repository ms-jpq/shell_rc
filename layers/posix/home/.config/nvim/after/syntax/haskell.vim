syntax clear ConcealGE
syntax clear ConcealLE
syntax clear ConcealNE

syntax match hsImport "\<import\>" conceal cchar=↓

syntax match hsRet "\<return\>" conceal cchar=⏎

syntax match hsCommentEdge '^\s*\zs--' containedin=hsLineComment conceal cchar=┃
