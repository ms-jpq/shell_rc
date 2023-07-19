#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from argparse import ArgumentParser, Namespace
from configparser import RawConfigParser
from itertools import chain
from json import dumps
from locale import strxfrm
from logging import INFO, StreamHandler, getLogger
from os import environ, execle, linesep
from os.path import normcase
from pathlib import Path, PurePath
from shlex import shlex
from shutil import which
from string import Template, whitespace
from sys import exit
from typing import Iterable, Iterator, Mapping, MutableMapping, MutableSequence, Tuple
from uuid import uuid4

log = getLogger()
log.setLevel(INFO)
log.addHandler(StreamHandler())


def _parse(text: str) -> Iterator[Tuple[str, str]]:
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
    parser.read_string(lines)
    for section in parser.values():
        yield from section.items()


def _subst(val: str, env: Mapping[str, str]) -> str:
    def cont() -> Iterator[str]:
        lex = shlex(val, posix=True)
        lex.whitespace = ""
        tmp: MutableSequence[str] = []

        for token in lex:
            if token.isspace():
                yield Template("".join(tmp)).substitute(env)
                tmp.clear()
                yield token
            else:
                tmp.append(token)

        yield Template("".join(tmp)).substitute(env)

    try:
        parsed = "".join(cont())
    except (KeyError, ValueError) as e:
        log.error(
            f"> %s{linesep}%s",
            e,
            dumps(val, ensure_ascii=False),
        )
        exit(True)
    else:
        return parsed.encode("utf-8").decode("unicode_escape")


def _trans(
    stream: Iterable[Tuple[str, str]], env: Mapping[str, str]
) -> Mapping[str, str]:
    seen: MutableMapping[str, str] = {}
    for key, val in stream:
        if key not in env:
            seen[key] = _subst(val, env={**seen, **env})

    return seen


def _print(env: Mapping[str, str]) -> None:
    ws = {*whitespace}

    def cont() -> Iterable[str]:
        ordered = sorted(env.items(), key=lambda kv: tuple(map(strxfrm, kv)))
        for key, val in ordered:
            lhs = "".join(
                char.encode("unicode_escape").decode("utf-8") if char in ws else char
                for char in key
            )
            rhs = dumps(val, ensure_ascii=False)
            yield f"{lhs}={rhs}"

    log.info("%s", linesep.join(cont()))


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

    p_env = {**environ}
    env = _trans(_parse(dotenv), env=p_env)

    _print(env)
    if cmd := which(args.arg0):
        execle(cmd, normcase(cmd), *args.argv, {**env, **p_env})
    else:
        raise OSError(args.arg0)


main()
