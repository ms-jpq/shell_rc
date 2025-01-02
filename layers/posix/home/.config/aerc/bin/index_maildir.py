#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from argparse import ArgumentParser, Namespace
from collections.abc import Iterator, MutableMapping
from contextlib import contextmanager, nullcontext, suppress
from datetime import datetime
from email.errors import HeaderParseError
from email.header import decode_header
from email.utils import getaddresses, parsedate_to_datetime, unquote
from hashlib import md5
from itertools import chain
from logging import INFO, StreamHandler, captureWarnings, getLogger
from mailbox import Maildir, MaildirMessage
from os import linesep
from os.path import pathsep
from pathlib import Path, PurePath
from sys import exit
from typing import Any, Callable, Sequence, TypeVar, cast
from unicodedata import normalize

_T = TypeVar("_T")
_U = TypeVar("_U")


def _parse_args() -> Namespace:
    parser = ArgumentParser()
    parser.add_argument(
        "--maildirs",
        type=Path,
        default=Path.home() / ".local" / "share" / "maildir",
    )
    parser.add_argument(
        "--cache",
        type=Path,
        default=Path.home() / ".cache" / "maildir",
    )
    parser.add_argument("--clear", action="store_true")
    return parser.parse_args()


def _maildirs(root: Path) -> Iterator[tuple[str, Path, Maildir]]:
    for mailboxes in root.glob("*/"):
        for globbed in mailboxes.rglob(".mbsyncstate"):
            if globbed.is_file():
                path = globbed.parent
                yield mailboxes.name, path, Maildir(path)


def _decode(name: str) -> Iterator[str]:
    with suppress(HeaderParseError):
        for lhs, rhs in decode_header(name):
            if isinstance(lhs, bytes) and isinstance(rhs, str):
                with suppress(UnicodeDecodeError):
                    yield lhs.decode(rhs)
            elif isinstance(lhs, str):
                yield lhs
            else:
                assert False, (lhs, rhs)


def _normalize(name: str) -> str:
    norm = normalize("NFKC", " ".join(name.split()))
    return unquote(norm)


def _standardize(addr: str) -> str | None:
    name, sep, domain = addr.strip().partition("@")
    if sep != "@":
        return None

    return name + sep + domain.casefold()


def _mtime(mail: MaildirMessage) -> float | None:
    for hdr, postpend in (
        ("date", False),
        ("received", True),
        ("x-received", True),
        ("resent-date", False),
    ):
        for header in mail.get_all(hdr, []):
            if postpend:
                _, _, value = header.partition(";")
            else:
                value = header

            with suppress(ValueError):
                if parsed := parsedate_to_datetime(value):
                    assert isinstance(parsed, datetime)
                    return parsed.timestamp()

    return None


def _parse(mail: MaildirMessage) -> Iterator[tuple[str, str]]:
    for hdr in ("from", "to", "cc", "bcc"):
        for label, addr in getaddresses(mail.get_all(hdr, [])):
            if parsed := _standardize(addr):
                for name in _decode(label):
                    normalized = _normalize(name)
                    yield parsed, "" if normalized == parsed else normalized


def _iter_keys(root: Path) -> Iterator[tuple[str, Maildir, Iterator[Path]]]:
    for mailbox, dir, maildir in _maildirs(root):
        paths = (dir.joinpath(subdir).iterdir() for subdir in ("cur", "new"))
        yield mailbox, maildir, chain.from_iterable(paths)


@contextmanager
def _cache(
    f: Path, sep: str, l: Callable[[str], _T], r: Callable[[str], _U]
) -> Iterator[MutableMapping[_T, _U]]:
    f.touch()
    cached: MutableMapping[_T, _U] = {}
    with f.open() as fd:
        for line in fd:
            if not line:
                continue

            key, s, value = line.partition(sep)
            if s != sep:
                continue

            with suppress(ValueError):
                cached[l(key)] = r(value)

    try:
        yield cached
    finally:
        ordered = sorted(cached.items(), key=lambda x: cast(Any, x[1]))
        gen = (
            f"{key}{sep}{sep.join(map(str, val)) if isinstance(val, Sequence) else val}{linesep}"
            for key, val in ordered
        )
        with f.open("w") as fd:
            fd.writelines(gen)


def _die(addr: str) -> bool:
    return (
        "reply" in addr
        or "notification" in addr
        or "invitation" in addr
        or "inbound" in addr
        or "notify" in addr
    )


def _parse_cache(row: str) -> tuple[float, str]:
    lhs, _, rhs = row.partition(" ")
    return float(lhs), rhs


def _run(cache_dir: Path, mail_dirs: Path) -> None:
    with _cache(cache_dir / "messages.txt", sep="\0", l=PurePath, r=float) as cache:
        for mailbox, maildir, paths in _iter_keys(mail_dirs):
            with _cache(
                cache_dir / f"addr.{mailbox}.txt", sep=" ", l=str, r=_parse_cache
            ) as mcache:
                for path in paths:
                    key, sep, _ = path.name.partition(pathsep)
                    if sep != pathsep:
                        continue

                    with suppress(FileNotFoundError):
                        mtime = path.stat().st_mtime
                        if mtime <= cache.get(path, 0):
                            continue

                        cache[path] = mtime

                        with suppress(KeyError):
                            message = maildir[key]
                            recency = _mtime(message) or mtime

                            for email, name in _parse(message):
                                if _die(email):
                                    continue

                                row = f"{email}\t{name}"
                                hashed = md5(row.encode()).hexdigest()

                                cached = mcache.get(hashed)
                                if cached is None:
                                    stored = recency
                                    log.info("%s", f"{email} :: {name}")
                                else:
                                    stored, _ = cached
                                    stored *= -1

                                mcache[hashed] = (-max(stored, recency), row)


def main() -> None:
    args = _parse_args()
    cache_dir = Path(args.cache)
    cache_dir.mkdir(parents=True, exist_ok=True)

    if args.clear:
        for path in cache_dir.iterdir():
            path.unlink()
        return

    _run(cache_dir, Path(args.maildirs))


try:
    with nullcontext():
        captureWarnings(True)
        log = getLogger()
        log.setLevel(INFO)
        log.addHandler(StreamHandler())
    main()
except KeyboardInterrupt:
    exit(130)
