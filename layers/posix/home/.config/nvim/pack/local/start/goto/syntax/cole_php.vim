syntax match phpShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match phpShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match phpReq '^\s*\zs\<include\>' conceal cchar=↓
syntax match phpReq '^\s*\zs\<require\>' conceal cchar=↓

syntax match phpCommentEdge       '^\s*\zs#\ze!\@!' conceal cchar=│
syntax match phpCommentEdgeSlash  '^\s*\zs//' conceal cchar=│
syntax match phpReplResponseHash  '\%(^\s*#\s*\)\@<=|\ze\%(\s\|$)' conceal cchar=┇
syntax match phpReplResponseSlash '\%(^\s*//\s*\)\@<=|\ze\%(\s\|$)' conceal cchar=┇

syntax match phpBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match phpBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match phpBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
