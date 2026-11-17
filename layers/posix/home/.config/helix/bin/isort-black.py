#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from shutil import which
from subprocess import PIPE, Popen
from sys import exit

with (
    Popen(
        (command, "--", "-") if (command := which("ssort")) else ("tee",),
        stdout=PIPE,
    ) as ssort,
    Popen(
        ("isort", "--quiet", "--profile=black", "--", "-"),
        stdin=ssort.stdout,
        stdout=PIPE,
    ) as isort,
    Popen(("black", "--quiet", "--", "-"), stdin=isort.stdout) as black,
):
    assert ssort.stdout
    ssort.stdout.close()
    assert isort.stdout
    isort.stdout.close()

exit(ssort.returncode or isort.returncode or black.returncode)
