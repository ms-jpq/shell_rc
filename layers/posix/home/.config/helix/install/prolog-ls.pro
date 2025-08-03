#!/usr/bin/env -S -- swipl

:- initialization(main, main).

main(_Argv) :-
    getenv('LIB', Lib),
    =(Pack, lsp_server),
    pack_install(Pack,
                 [ package_directory(Lib),
                   global(false),
                   upgrade(true),
                   interactive(false)
                 ]).
