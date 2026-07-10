syntax clear ConcealNE

syntax match jsReq "\<require\>" conceal cchar=←
syntax match jsFrom "\<from\>" conceal cchar=←
syntax match jsImport "\<import\>" conceal cchar=↓

syntax match jsFunc "\<function\>" conceal cchar=ƒ

syntax match jsRet "@\@<!\<return\>" conceal cchar=⏎
