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

install(Pack, Attempts) :-
    catch(install(Pack), Error,
          ( Error = error(existence_error(url, _), context(_, status(Code, _))),
            Code >= 500, Code < 600, Attempts > 1
          -> print_message(warning, Error),
             sleep(2),
             Remaining is Attempts - 1,
             install(Pack, Remaining)
          ;  throw(Error)
          )).

main(_Argv) :-
    install('lsp_server', 3).
