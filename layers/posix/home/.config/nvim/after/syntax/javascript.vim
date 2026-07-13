syntax clear ConcealNE

syntax match jsFrom "\.\@<!\<from\>" conceal cchar=←
syntax match jsReq "\<require\>" conceal cchar=←
syntax match jsImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match jsCommentEdge '^\s*\zs//' conceal cchar=│

syntax match jsBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match jsBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match jsBlockCommentClose '^\s*\zs\*\/' conceal cchar=└
