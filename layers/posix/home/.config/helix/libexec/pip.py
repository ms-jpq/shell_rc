#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from os import execlp, linesep, name
from os.path import join
from pathlib import Path
from sys import argv, exit
from tempfile import gettempdir

try:
    from venv import create
except ImportError:
    exit(0)

_, pkg, *pkgs = map(lambda s: s.strip(), argv)
requirements = linesep.join((pkg, *pkgs))
home = Path.home() / ".cache" / "helix-rt" / "python" / pkg
txt = home / "requirements.txt"
venv = home / "venv"
python = venv / ("Scripts" if name == "nt" else "bin") / "python"

home.mkdir(parents=True, exist_ok=True)
txt.write_text(requirements)

create(venv, with_pip=True)
execlp(
    python,
    python,
    "-m",
    "pip",
    "--disable-pip-version-check",
    "--quiet",
    "--cache-dir",
    join(gettempdir(), "pip"),
    "install",
    "--require-virtualenv",
    "--upgrade",
    "--requirement",
    txt,
)
