syntax match dartImport "\<import\>" conceal cchar=↓

syntax match dartCommentEdge '^\s*\zs//' containedin=dartLineComment conceal cchar=│

syntax match dartBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' containedin=dartComment conceal cchar=│

syntax match dartBlockCommentOpen '^\s*\zs\/\*' containedin=dartComment conceal cchar=┌
syntax match dartBlockCommentClose '^\s*\zs\*\/' containedin=dartComment conceal cchar=└
