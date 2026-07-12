#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from argparse import ArgumentParser, Namespace
from collections.abc import Iterator
from concurrent.futures import (
    Future,
    ProcessPoolExecutor,
    ThreadPoolExecutor,
    as_completed,
)
from contextlib import nullcontext, suppress
from datetime import datetime
from email import message_from_bytes
from email.errors import HeaderParseError
from email.header import decode_header
from email.message import EmailMessage
from email.policy import SMTP, SMTPUTF8
from email.utils import getaddresses, parsedate_to_datetime, unquote
from functools import partial
from itertools import chain, takewhile
from logging import INFO, basicConfig, captureWarnings, getLogger
from os import environ, linesep
from os.path import normcase, sep
from pathlib import Path
from sys import exit
from typing import MutableSequence, MutableSet, Sequence
from unicodedata import normalize

_Processed = tuple[Path, Sequence[tuple[float, str]]] | None

_NL = SMTP.linesep.encode()
_LS = linesep.encode()
_FLAG = "RECUR"

with nullcontext():
    captureWarnings(True)
    basicConfig(format="%(message)s", level=INFO)


def _die(addr: str, label: str) -> bool:
    return (
        False
        or len(addr) >= 50
        or "+" in addr
        or "bounce" in addr
        or "inbound" in addr
        or "invitation" in addr
        or "marketplace" in addr
        or "notification" in addr
        or "notify" in addr
        or "reply" in addr
        or "support" in addr
        or addr.endswith(
            (
                "amazonses.com",
                "ashbyhq.com",
                "docusign.net",
                "linkedin.com",
                "slack.com",
            )
        )
    ) or (False or " via " in label or " 通过 " in label)


def _read_headers(path: Path) -> EmailMessage | None:
    with suppress(FileNotFoundError):
        with path.open("rb") as f:
            lines = takewhile(lambda x: x not in {_NL, _LS}, iter(f.readline, b""))
            headers = b"".join(lines)

            email = message_from_bytes(headers, policy=SMTPUTF8)
            assert isinstance(email, EmailMessage)
            return email

    return None


def _mtime(mail: EmailMessage) -> float:
    for hdr, postpend in (
        ("date", False),
        ("received", True),
        ("x-received", True),
        ("resent-date", False),
    ):
        for header in mail.get_all(hdr, ()):
            if postpend:
                _, _, value = header.partition(";")
            else:
                value = header

            with suppress(ValueError):
                if parsed := parsedate_to_datetime(value):
                    assert isinstance(parsed, datetime)
                    return parsed.timestamp()

    return 0.0


def _decode(name: str) -> Iterator[str]:
    with suppress(HeaderParseError):
        for lhs, rhs in decode_header(name):
            match (lhs, rhs):
                case (bytes(), str()):
                    with suppress(UnicodeDecodeError):
                        yield lhs.decode(rhs)
                case (str(), _):
                    yield lhs
                case _:
                    assert False, (lhs, rhs)


def _standardize(addr: str) -> str | None:
    name, sep, domain = addr.strip().partition("@")
    if sep != "@":
        return None

    # NOT RFC5321 compliant
    return name.casefold() + sep + domain.casefold()


def _normalize(name: str) -> str:
    norm = normalize("NFKC", " ".join(name.split()))
    return unquote(norm)


def _parse(mail: EmailMessage) -> Iterator[tuple[str, str]]:
    for hdr in ("from", "to", "cc", "bcc", "return-path"):
        for label, addr in getaddresses(mail.get_all(hdr, ())):
            if parsed := _standardize(addr):
                for name in _decode(label):
                    normalized = _normalize(name)
                    yield parsed, "" if normalized == parsed.casefold() else normalized


def _process_mail(mail: Path) -> _Processed:
    if not (headers := _read_headers(mail)):
        return None

    mtime = _mtime(headers)
    addrs = tuple(
        (mtime, f"{addr}\t{label}")
        for addr, label in _parse(headers)
        if not _die(addr, label=label)
    )
    return mail, addrs


def _process_account(cache_dir: Path, account: Path) -> None:
    stem = cache_dir.joinpath(account.name)
    cache, out = stem.with_suffix(".cache.txt"), stem.with_suffix(".addr.txt")
    for p in (cache, out):
        p.touch()

    seen = frozenset(cache.read_text().split("\0"))
    compiled = {
        rhs: float(lhs)
        for lhs, rhs in (
            line.split(" ", maxsplit=1) for line in out.read_text().splitlines()
        )
    }
    maildirs = chain.from_iterable(
        (
            globbed.parent.iterdir()
            for globbed in account.rglob(".mbsyncstate")
            if globbed.is_file()
        )
    )
    mails = chain.from_iterable(
        dir.iterdir() for dir in maildirs if dir.name in ("new", "cur")
    )
    unseen = (mail for mail in mails if normcase(mail) not in seen)
    added: MutableSet[str] = set()

    def cont(fut: Future[_Processed]) -> None:
        row = fut.result()
        if not row:
            return
        path, addrs = row
        added.add(normcase(path))
        for mtime, addr in addrs:
            if addr not in compiled:
                getLogger().info("%s", addr)
            compiled[addr] = max(compiled.get(addr, mtime), mtime)

    try:
        with ThreadPoolExecutor() as ex:
            futs: MutableSequence[Future[_Processed]] = []
            for fut in (ex.submit(_process_mail, path) for path in unseen):
                fut.add_done_callback(cont)
                futs.append(fut)
            tuple(as_completed(futs))

    finally:
        ordered = sorted(compiled.items(), key=lambda x: x[1], reverse=True)
        saw = "\0".join(chain(seen, added))
        updated = linesep.join(f"{mtime} {addr}" for addr, mtime in ordered)
        cache.write_text(saw)
        out.write_text(updated)


def _parse_args() -> Namespace:
    parser = ArgumentParser()
    home = Path.home()
    parser.add_argument(
        "--maildirs",
        type=Path,
        default=home / ".local" / "share" / "maildir",
    )
    parser.add_argument(
        "--cache",
        type=Path,
        default=home / ".cache" / "maildir",
    )
    parser.add_argument("--clear", action="store_true")
    return parser.parse_args()


def _main() -> None:
    args = _parse_args()
    cache_dir = Path(args.cache)
    cache_dir.mkdir(parents=True, exist_ok=True)

    if args.clear:
        for path in cache_dir.iterdir():
            path.unlink()

    environ[_FLAG] = "1"
    with ProcessPoolExecutor() as ex:
        proc = partial(_process_account, cache_dir)
        accounts = Path(args.maildirs).glob("*" + sep)
        tuple(ex.map(proc, accounts))


try:
    if not _FLAG in environ:
        _main()
except KeyboardInterrupt:
    exit(130)
