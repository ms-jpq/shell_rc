syntax clear ConcealNE

syntax match phpFunc "\<function\>" conceal cchar=ƒ

syntax match phpRet "@\@<!\<return\>" conceal cchar=⏎
