autocmd BufWinLeave * if expand("<afile>") != "" | write | call writefile([], expand("<afile>") . ".done") | endif
