syntax clear ConcealNE

syntax match jsFrom "\<from\>" conceal cchar=←
syntax match jsImport "\<import\>" conceal cchar=↓

syntax match jsFunc "\<function\>" conceal cchar=ƒ

syntax match jsRet "\v\@<!\<return\>" conceal cchar=⏎
