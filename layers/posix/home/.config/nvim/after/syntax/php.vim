syntax clear ConcealNE

syntax match phpFunc "\<function\>" conceal cchar=ƒ

syntax match phpRet "\v\@<!\<return\>" conceal cchar=⏎
