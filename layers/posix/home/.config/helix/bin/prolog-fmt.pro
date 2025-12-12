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

stdin_to_file(Tmp) :-
    setup_call_cleanup(
        open(Tmp, write, Out),
        copy_stream_data(user_input, Out),
        close(Out)
    ).

file_to_stdout(Tmp) :-
    setup_call_cleanup(
        open(Tmp, read, Out),
        copy_stream_data(Out, user_output),
        close(Out)
    ).

run_fmt(Fmt, Tmp) :-
    append([Fmt], ['--', '--', Tmp], ArgV),
    stdin_to_file(Tmp),
    process_create(path('swipl'), ArgV, []),
    file_to_stdout(Tmp).

main(_Argv) :-
    lsp(Dir),
    directory_file_path(Dir, app, App),
    directory_file_path(App, 'formatter.pl', Fmt),
    setup_call_cleanup(
        tmp_file('prolog-fmt', Tmp),
        run_fmt(Fmt, Tmp),
        delete_file(Tmp)
    ).
