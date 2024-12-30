#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from argparse import ArgumentParser, Namespace
from contextlib import suppress
from email.errors import HeaderParseError
from email.header import decode_header
from email.utils import getaddresses
from itertools import chain
from mailbox import Maildir, MaildirMessage
from os.path import pathsep
from pathlib import Path
from sys import exit
from typing import Iterator


def _parse_args() -> Namespace:
    parser = ArgumentParser()
    parser.add_argument(
        "--maildirs",
        type=Path,
        default=Path.home() / ".local" / "share" / "maildir",
    )
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


def _parse(mail: MaildirMessage) -> Iterator[tuple[str, str]]:
    for hdr in ("from", "to", "cc", "bcc"):
        for label, addr in getaddresses(mail.get_all(hdr, [])):
            for name in _decode(label):
                yield addr, name


def _iter_keys(root: Path) -> Iterator[tuple[str, Maildir, Iterator[Path]]]:
    for mailbox, dir, maildir in _maildirs(root):
        paths = (dir.joinpath(subdir).iterdir() for subdir in ("cur", "new"))
        yield mailbox, maildir, chain.from_iterable(paths)


def main() -> None:
    args = _parse_args()
    for mailbox, maildir, paths in _iter_keys(Path(args.maildirs)):
        for path in paths:
            key, sep, _ = path.name.partition(pathsep)
            if sep != pathsep:
                continue

            with suppress(KeyError):
                message = maildir[key]
                for addr, name in _parse(message):
                    print(addr, name)


try:
    main()
except KeyboardInterrupt:
    exit(130)
