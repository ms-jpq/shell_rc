syntax match cRet "\<return\>" conceal cchar=⏎

syntax match cCommentEdge '^\s*\zs//' containedin=cCommentL conceal cchar=┃
