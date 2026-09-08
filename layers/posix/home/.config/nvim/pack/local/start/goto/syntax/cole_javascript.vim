syntax match jsShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match jsShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match jsFrom "\.\@<!\<from\>" conceal cchar=←
syntax match jsReq "\<require\ze\s*(" conceal cchar=←
syntax match jsImport '^\s*\zs\<import\>' conceal cchar=↓

syntax match jsCommentEdge  '^\s*\zs//' conceal cchar=│
syntax match jsReplResponse '^\s*\zs//\s*|' conceal cchar=┇

syntax match jsBlockCommentEdge '^\s*\/\@<!\zs\*\/\@!' conceal cchar=│

syntax match jsBlockCommentOpen '^\s*\zs\/\*' conceal cchar=┌
syntax match jsBlockCommentDoc '\%(^\s*/\*\)\@<=\*' conceal cchar=┐
syntax match jsBlockCommentClose '^\s*\zs\*\/' conceal cchar=└

syntax match jsBlockCommentInline '^\s*\zs/\*.\{-}\*/' transparent contains=jsBlockCommentInlineOpen,jsBlockCommentInlineDoc,jsBlockCommentInlineClose
syntax match jsBlockCommentInlineOpen '/\*' contained conceal cchar=┌
syntax match jsBlockCommentInlineDoc '\%(/\*\)\@<=\*/\@!' contained conceal cchar=─
syntax match jsBlockCommentInlineClose '\*/' contained conceal cchar=┘
