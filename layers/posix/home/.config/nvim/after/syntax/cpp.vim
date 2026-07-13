syntax match cppRet "\<return\>" conceal cchar=⏎

syntax match cppCommentEdge '^\s*\zs//' containedin=cCommentL conceal cchar=┃
