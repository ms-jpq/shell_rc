syntax match cppCommentEdge '^\s*\zs//' containedin=cCommentL conceal cchar=│

syntax match cppBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' containedin=cComment conceal cchar=│

syntax match cppBlockCommentOpen '^\s*\zs\/\*' containedin=cComment conceal cchar=┌
syntax match cppBlockCommentClose '^\s*\zs\*\/' containedin=cComment conceal cchar=└
