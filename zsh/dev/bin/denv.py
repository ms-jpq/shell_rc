#!/usr/bin/env -S -- PYTHONSAFEPATH= /usr/bin/python3

from argparse import ArgumentParser, Namespace
from collections.abc import (
    Generator,
    Iterable,
    Iterator,
    Mapping,
    MutableMapping,
)
from contextlib import contextmanager, nullcontext
from enum import Enum
from itertools import chain
from json import dumps
from logging import INFO, basicConfig, captureWarnings, getLogger
from os import environ, execle, name, pathsep
from pathlib import Path, PurePath
from re import RegexFlag, compile
from shlex import quote, split
from shutil import which
from string import Template
from sys import exit, stderr, stdout

_CODEC = "utf-8"
_IS_TTY = stdout.isatty() and stderr.isatty()
_IS_WIN = name == "nt"
_RE = compile(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", flags=RegexFlag.DOTALL)


with nullcontext():
    captureWarnings(True)
    basicConfig(format="%(message)s", level=INFO)


class _State(Enum):
    NORM = 0
    EXPORT = 1


def _parse(text: str) -> Iterator[tuple[str, str]]:
    state = _State.NORM
    for token in split(text, comments=True):
        if state is _State.NORM:
            if token == "export":
                state = _State.EXPORT
                continue

        elif state is _State.EXPORT:
            if token == "--":
                continue

            state = _State.NORM
        else:
            assert False

        if match := _RE.match(token):
            yield match.group(1), match.group(2)
        else:
            assert False, token

    assert state is _State.NORM


def _quote(text: str) -> str:
    return quote(dumps(text, ensure_ascii=False)[1:-1])


def _print(key: str, val: str) -> None:
    if _IS_TTY:
        lhs, rhs = _quote(key), _quote(val)
        getLogger().info("%s", f">> {lhs}={rhs}")


@contextmanager
def _man() -> Generator[None]:
    if _IS_TTY:
        getLogger().info("%s", f"<<")
    try:
        yield None
    finally:
        if _IS_TTY:
            getLogger().info("%s", f"<<")


@_man()
def _accumulate(stream: Iterable[tuple[str, str]]) -> MutableMapping[str, str]:
    env = {**environ}

    for key, val in stream:
        env[key] = val = Template(val).substitute(env)
        _print(key, val)

    return env


def _workdir() -> Path:
    cwd = Path.cwd()
    for parent in chain((cwd,), cwd.parents):
        if parent.joinpath(".git").is_dir():
            return parent
    else:
        return cwd


def _path(env: Mapping[str, str]) -> Iterator[str]:
    work_dir = _workdir()
    for dir in (
        work_dir / ".venv" / ("Scripts" if _IS_WIN else "bin"),
        work_dir / "node_modules" / ".bin",
    ):
        if dir.is_dir():
            yield str(dir)

    if p := env.get("PATH"):
        yield p


def _arg_parse() -> Namespace:
    parser = ArgumentParser(add_help=False)
    parser.add_argument("path", type=PurePath)
    parser.add_argument("arg0")
    parser.add_argument("argv", nargs="...")
    return parser.parse_args()


def main() -> None:
    args = _arg_parse()

    env_path = Path(args.path)
    dotenv = "" if env_path == PurePath("-") else env_path.read_text(_CODEC)

    env = _accumulate(_parse(dotenv))
    env["PATH"] = path = pathsep.join(_path(env))

    if cmd := which(args.arg0, path=path):
        execle(cmd, cmd, *args.argv, env)
    else:
        raise OSError(args.arg0)


try:
    main()
except KeyboardInterrupt:
    exit(130)
