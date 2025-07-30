#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from concurrent.futures import ThreadPoolExecutor
from os import close, pipe
from subprocess import check_call


def _isort(w: int) -> None:
    try:
        check_call(("isort", "--profile=black", "--", "-"), stdout=w)
    finally:
        close(w)


def _black(r: int) -> None:
    try:
        check_call(("black", "--", "-"), stdin=r)
    finally:
        close(r)


def _main() -> None:
    with ThreadPoolExecutor() as ex:
        mapped = ex.map(lambda a: a[0](a[1]), zip((_black, _isort), pipe()))
        tuple(mapped)


_main()
