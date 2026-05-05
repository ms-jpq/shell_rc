#!/usr/bin/env -S -- PYTHONSAFEPATH= /usr/bin/python3

from argparse import ArgumentParser, Namespace
from collections.abc import (
    Generator,
    Iterable,
    Iterator,
    Mapping,
    MutableMapping,
    MutableSequence,
)
from configparser import RawConfigParser
from contextlib import contextmanager, nullcontext
from functools import lru_cache
from itertools import chain
from json import dumps
from logging import INFO, basicConfig, captureWarnings, getLogger
from os import environ, execle, linesep, name
from os.path import normcase
from pathlib import Path, PurePath
from shlex import quote, shlex
from shutil import which
from string import Template
from sys import exit, stderr, stdout
from typing import Optional, Tuple
from unicodedata import normalize
from uuid import uuid4

_CODEC = "utf-8"

with nullcontext():
    captureWarnings(True)
    basicConfig(format="%(message)s", level=INFO)


def _parse(text: str) -> Iterator[Tuple[str, Optional[str]]]:
    class _Parser(RawConfigParser):
        def optionxform(self, optionstr: str) -> str:
            return optionstr

    lines = "".join(chain((f"[{uuid4()}]", linesep), text))
    parser = _Parser(
        allow_no_value=True,
        strict=False,
        interpolation=None,
        comment_prefixes=("#",),
        delimiters=("=",),
    )

    try:
        parser.read_string(lines)
    except AttributeError:
        ls = linesep.join(f">! {line}" for line in text.splitlines())
        getLogger().error("%s", ls)
        exit(True)
    else:
        for section in parser.values():
            yield from section.items()


def _decode(text: str) -> str:
    return text.encode(_CODEC).decode("unicode_escape")


def _codec(text: str) -> str:
    def cont() -> Iterator[str]:
        acc: MutableSequence[str] = []
        for ch in text:
            if ch.isascii():
                acc.append(ch)
            else:
                yield _decode("".join(acc))
                acc.clear()
                yield ch

        yield _decode("".join(acc))

    try:
        return "".join(cont())
    except UnicodeDecodeError as e:
        es = repr(type(e))
        getLogger().error("%s", f">! {es}")
        exit(True)


def _subst(val: str, env: Mapping[str, str]) -> str:
    if val.startswith("'") and val.endswith("'"):
        return val[1:-1]
    else:
        text = _codec(val)

    def cont() -> Iterator[str]:
        lex = shlex(text, posix=True)
        lex.whitespace = ""
        acc: MutableSequence[str] = []

        for token in lex:
            if token.isspace():
                yield Template("".join(acc)).substitute(env)
                acc.clear()
                yield token
            else:
                acc.append(token)

        yield Template("".join(acc)).substitute(env)

    try:
        parsed = "".join(cont())
    except (KeyError, ValueError) as e:
        es = repr(type(e)(text))
        getLogger().error("%s", f">! {es}")
        exit(True)
    else:
        return parsed


def _quote(text: str) -> str:
    return quote(dumps(text, ensure_ascii=False)[1:-1])


@lru_cache(maxsize=None)
def _isatty() -> bool:
    return stdout.isatty() and stderr.isatty()


def _print(key: str, val: str) -> None:
    lhs = _quote(key)
    rhs = _quote(val)
    if _isatty():
        getLogger().info("%s", f">> {lhs}={rhs}")


@contextmanager
def _man() -> Generator[None]:
    if _isatty():
        getLogger().info("%s", f"<<")
    try:
        yield None
    finally:
        if _isatty():
            getLogger().info("%s", f"<<")


@_man()
def _trans(
    stream: Iterable[Tuple[str, Optional[str]]], env: Mapping[str, str]
) -> Mapping[str, str]:
    seen: MutableMapping[str, str] = {}

    for key, val in stream:
        if val is None:
            es = repr(ValueError(key))
            getLogger().error("%s", f">! {es}")
            exit(True)

        if key not in env:
            seen[key] = val = _subst(val, env={**seen, **env})
        _print(key, val)

    return seen


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

    norm = normalize("NFKD", dotenv)
    p_env = {**environ}
    env = _trans(_parse(norm), env=p_env)
    pass_through = {
        "ASDF_DATA_DIR",
        "AWS_SHARED_CREDENTIALS_FILE",
        "EDITOR",
        "HOME",
        "LC_ALL",
        "LESS",
        "PAGER",
        "PATH",
        "SHELL",
        "SSH_AUTH_SOCK",
        "TERM",
        "TIME_STYLE",
        "TMPDIR",
        "TMUX",
        "TMUX_PANE",
        "TMUX_TMPDIR",
        "TZ",
        "USER",
        "XDG_CACHE_HOME",
        "XDG_CONFIG_HOME",
        "XDG_DATA_HOME",
        "XDG_STATE_HOME",
    }
    if name == "nt":
        pass_through |= {"PATHEXT"}
    new_env = {**env, **{k: v for k, v in p_env.items() if k in pass_through}}

    if cmd := which(args.arg0):
        execle(cmd, normcase(cmd), *args.argv, new_env)
    else:
        raise OSError(args.arg0)


try:
    main()
except KeyboardInterrupt:
    exit(130)
