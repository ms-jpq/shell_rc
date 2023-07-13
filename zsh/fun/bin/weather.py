#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from argparse import ArgumentParser, Namespace
from enum import Enum, auto
from http.client import HTTPResponse
from locale import getdefaultlocale
from typing import Optional, cast
from urllib.request import Request, build_opener


class _Fmt(Enum):
    line = auto()
    table = auto()
    graph = auto()


def _lang() -> Optional[str]:
    tag, _ = getdefaultlocale()
    if not tag:
        return None
    else:
        primary, _, _ = tag.casefold().partition("-")
        lang, _, _ = primary.partition("_")
        return lang


def _wttrin_uri(display: _Fmt) -> str:
    if display is _Fmt.line:
        return "https://wttr.in?m&format=4"
    elif display is _Fmt.table:
        return "https://wttr.in?mT"
    elif display is _Fmt.graph:
        return "https://v2.wttr.in?mT"
    else:
        raise ValueError()


def _wttrin(fmt: _Fmt) -> str:
    lang = _lang()
    uri = _wttrin_uri(fmt)
    headers = {**{"User-Agent": "curl"}, **({"Accept-Language": lang} if lang else {})}
    req = Request(uri, headers=headers)

    opener = build_opener()
    with opener.open(req) as resp:
        return cast(HTTPResponse, resp).read().decode()


def _parse_args() -> Namespace:
    parser = ArgumentParser()
    parser.add_argument(
        "format",
        nargs="?",
        choices=tuple(f.name for f in _Fmt),
        default=_Fmt.graph.name,
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    fmt = _Fmt[args.format]
    resp = _wttrin(fmt)
    print(resp)


main()
