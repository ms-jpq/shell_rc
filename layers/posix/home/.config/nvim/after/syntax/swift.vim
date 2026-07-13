syntax match swiftImport "\<import\>" conceal cchar=↓

syntax match swiftCommentEdge '^\s*\zs//' containedin=swiftLineComment conceal cchar=│

syntax match swiftBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' containedin=swiftComment conceal cchar=│

syntax match swiftBlockCommentOpen '^\s*\zs\/\*' containedin=swiftComment conceal cchar=┌
syntax match swiftBlockCommentClose '^\s*\zs\*\/' containedin=swiftComment conceal cchar=└
