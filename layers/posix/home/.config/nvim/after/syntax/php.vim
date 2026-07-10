syntax clear ConcealNE

syntax match phpReq "\<include\>" conceal cchar=↓
syntax match phpReq "\<require\>" conceal cchar=↓

syntax match phpFunc "\<function\>" conceal cchar=ƒ

syntax match phpRet "@\@<!\<return\>" conceal cchar=⏎
