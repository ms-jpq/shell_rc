syntax match rustShebangHash '\%1l^#\ze!' conceal cchar=⌘
syntax match rustShebangBang '\%1l\(^#\)\@<=!/usr/bin/env\ze\%(\s\|$\)' conceal cchar=‼

syntax match rustUse '^\s*\zs\<use\>' conceal cchar=↓

syntax match rustCommentEdge '^\s*\zs//' conceal cchar=│

syntax match rustBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match rustBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match rustBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
