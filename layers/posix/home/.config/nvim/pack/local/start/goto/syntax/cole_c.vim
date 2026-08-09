syntax match cShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match cShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match cInclude '^\s*\zs#include\>' conceal cchar=↓

syntax match cCommentEdge  '^\s*\zs//' conceal cchar=│
syntax match cReplResponse '\%(^\s*//\s*\)\@<=|\ze\%(\s\|$)' conceal cchar=┇

syntax match cBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match cBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match cBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
