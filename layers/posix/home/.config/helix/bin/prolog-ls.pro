#!/usr/bin/env -S -- swipl

:- initialization(main, main).

lsp(Dir) :-
    getenv('HOME', Home),
    directory_file_path(Home, '.cache', Cache),
    directory_file_path(Cache, 'helix-rt', HelixRT),
    directory_file_path(HelixRT, more, More),
    directory_file_path(More, 'prolog-ls.pro', PrologLS),
    directory_file_path(PrologLS, 'lib', Lib),
    directory_file_path(Lib, 'lsp_server', Dir).

main(_Argv) :-
    set_prolog_flag(argv, [stdio]),
    current_prolog_flag(argv, ArgV),
    lsp(Dir),
    pack_attach(Dir, []),
    use_module(library('lsp_server')),
    lsp_server:main.
