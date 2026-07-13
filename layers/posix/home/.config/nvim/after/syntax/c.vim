syntax match cCommentEdge '^\s*\zs//' containedin=cCommentL conceal cchar=│

syntax match cBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' containedin=cComment conceal cchar=│

syntax match cBlockCommentOpen '^\s*\zs\/\*' containedin=cComment conceal cchar=┌
syntax match cBlockCommentClose '^\s*\zs\*\/' containedin=cComment conceal cchar=└
