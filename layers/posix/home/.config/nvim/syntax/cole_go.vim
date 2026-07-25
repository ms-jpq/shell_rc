syntax match goShebangHash '\%1l^#\ze!' conceal cchar=⌘
syntax match goShebangBang '\%1l\(^#\)\@<=!/usr/bin/env\ze\%(\s\|$\)' conceal cchar=‼

syntax match goImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match goCommentEdge '^\s*\zs//' conceal cchar=│

syntax match goBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match goBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match goBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
