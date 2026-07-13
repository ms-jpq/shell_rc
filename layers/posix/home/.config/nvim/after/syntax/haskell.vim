syntax match hsImport "\<import\>" conceal cchar=↓

syntax match hsCommentEdge '^\s*\zs--' containedin=hsLineComment conceal cchar=┃
