#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from subprocess import PIPE, Popen
from sys import exit

with (
    Popen(("isort", "--profile=black", "--", "-"), stdout=PIPE) as isort,
    Popen(("black", "--quiet", "--", "-"), stdin=isort.stdout) as black,
):
    assert isort.stdout
    isort.stdout.close()

exit(isort.returncode or black.returncode)
