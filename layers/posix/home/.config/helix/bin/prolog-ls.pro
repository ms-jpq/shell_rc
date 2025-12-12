#!/usr/bin/env -S -- swipl

:- initialization(main, main).

main(_Argv) :-
    getenv('HOME', Home),
    directory_file_path(Home, '.cache', Cache),
    directory_file_path(Cache, 'helix-rt', HelixRT),
    directory_file_path(HelixRT, more, More),
    directory_file_path(More, 'prolog-ls.pro', PrologLS),
    directory_file_path(PrologLS, lib, Lib),
    directory_file_path(Lib, lsp_server, LSP),
    set_prolog_flag(argv, [stdio]),
    current_prolog_flag(argv, ArgV),
    writeln(ArgV),
    pack_attach(LSP, []),
    use_module(library(lsp_server)),
    :(lsp_server, main),
    halt.
