syntax match cppCommentEdge '^\s*\zs//' conceal cchar=│

syntax match cppBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match cppBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match cppBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
