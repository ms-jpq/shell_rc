#!/usr/bin/env -S -- swipl

:- initialization(main, main).

install(Pack) :-
    getenv('LIB', Lib),
    directory_file_path(Lib, Pack, Dir),
    make_directory_path(Dir),
    pack_install(Pack,
                 [ package_directory(Lib),
                   global(false),
                   upgrade(true),
                   interactive(false)
                 ]).

main(_Argv) :-
    install('lsp_server').
