autocmd BufWinLeave * if expand("<afile>") != "" | call writefile([], expand("<afile>") . ".done") | wq! | endif
