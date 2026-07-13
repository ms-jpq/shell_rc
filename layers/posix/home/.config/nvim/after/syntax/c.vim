syntax match cCommentEdge '^\s*\zs//' conceal cchar=│

syntax match cBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match cBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match cBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
