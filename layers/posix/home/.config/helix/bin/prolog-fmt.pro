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
    current_prolog_flag(argv, ArgV),
    lsp(Dir),
    directory_file_path(Dir, app, App),
    directory_file_path(App, 'formatter.pl', Fmt),
    append([Fmt], ArgV, A),
    process_create(path('swipl'), A, []).
