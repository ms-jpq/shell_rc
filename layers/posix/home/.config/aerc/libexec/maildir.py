#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from argparse import ArgumentParser, Namespace
from contextlib import suppress
from email.errors import HeaderParseError
from email.header import decode_header
from email.utils import getaddresses
from mailbox import Maildir, MaildirMessage
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


def _maildirs(root: Path) -> Iterator[tuple[str, Maildir]]:
    for mailboxes in root.glob("*/"):
        for globbed in mailboxes.rglob(".mbsyncstate"):
            if globbed.is_file():
                yield mailboxes.name, Maildir(globbed.parent)


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
    for hdr in ("from", "cc", "bcc"):
        for label, addr in getaddresses(mail.get_all(hdr, [])):
            for name in _decode(label):
                yield addr, name


def main() -> None:
    args = _parse_args()
    for mailbox, maildir in _maildirs(Path(args.maildirs)):
        for message in maildir:
            for addr, name in _parse(message):
                print([mailbox, addr])


try:
    main()
except KeyboardInterrupt:
    exit(130)
