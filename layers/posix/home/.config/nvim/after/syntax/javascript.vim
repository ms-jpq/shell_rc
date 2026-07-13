syntax clear ConcealNE

syntax match jsFrom "\.\@<!\<from\>" conceal cchar=←
syntax match jsReq "\<require\>" conceal cchar=←
syntax match jsImport "\<import\>" conceal cchar=↓

syntax match jsCommentEdge '^\s*\zs//' containedin=javaScriptLineComment conceal cchar=│

syntax match jsBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' containedin=javaScriptComment conceal cchar=│

syntax match jsBlockCommentOpen '^\s*\zs\/\*' containedin=javaScriptComment conceal cchar=┌
syntax match jsBlockCommentClose '^\s*\zs\*\/' containedin=javaScriptComment conceal cchar=└
