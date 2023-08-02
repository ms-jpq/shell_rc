#!/usr/bin/env -S -- PYTHONSAFEPATH= /usr/bin/python3

from argparse import ArgumentParser, Namespace
from configparser import RawConfigParser
from contextlib import contextmanager
from itertools import chain
from json import dumps
from logging import INFO, StreamHandler, captureWarnings, getLogger
from os import environ, execle, linesep
from os.path import normcase
from pathlib import Path, PurePath
from shlex import quote, shlex
from shutil import which
from string import Template
from sys import exit
from typing import (
    Iterable,
    Iterator,
    Mapping,
    MutableMapping,
    MutableSequence,
    Optional,
    Tuple,
)
from unicodedata import normalize
from uuid import uuid4

captureWarnings(True)
log = getLogger()
log.setLevel(INFO)
log.addHandler(StreamHandler())


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
        log.error("%s", ls)
        exit(True)
    else:
        for section in parser.values():
            yield from section.items()


def _subst(val: str, env: Mapping[str, str]) -> str:
    def cont() -> Iterator[str]:
        if val.startswith("'") and val.endswith("'"):
            yield val[1:-1]
        else:
            lex = shlex(val, posix=True)
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
        es = repr(type(e)(val))
        log.error("%s", f">! {es}")
        exit(True)
    else:
        try:
            text = parsed.encode("utf-8").decode("unicode_escape")
        except UnicodeDecodeError as e:
            es = repr(type(e))
            log.error("%s", f">! {es}")
            exit(True)
        else:
            return text


def _quote(text: str) -> str:
    return quote("".join(dumps(ch, ensure_ascii=False)[1:-1] for ch in text))


def _print(key: str, val: str) -> None:
    lhs = _quote(key)
    rhs = _quote(val)
    log.info("%s", f">> {lhs}={rhs}")


@contextmanager
def _man() -> Iterator[None]:
    log.info("%s", f"<<")
    try:
        yield None
    finally:
        log.info("%s", f"<<")


def _trans(
    stream: Iterable[Tuple[str, Optional[str]]], env: Mapping[str, str]
) -> Mapping[str, str]:
    seen: MutableMapping[str, str] = {}

    with _man():
        for key, val in stream:
            if val is None:
                es = repr(ValueError(key))
                log.error("%s", f">! {es}")
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
    dotenv = "" if env_path == PurePath("-") else env_path.read_text("utf-8")

    norm = normalize("NFKD", dotenv)
    p_env = {**environ}
    env = _trans(_parse(norm), env=p_env)

    if cmd := which(args.arg0):
        execle(cmd, normcase(cmd), *args.argv, {**env, **p_env})
    else:
        raise OSError(args.arg0)


main()
