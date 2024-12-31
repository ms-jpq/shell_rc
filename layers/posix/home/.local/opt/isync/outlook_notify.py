#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from argparse import ArgumentParser, Namespace
from collections.abc import Iterator
from contextlib import contextmanager
from functools import lru_cache, partial
from imaplib import IMAP4, IMAP4_SSL
from logging import INFO, StreamHandler, captureWarnings, getLogger
from pathlib import Path
from selectors import EVENT_READ, DefaultSelector
from subprocess import check_output
from sys import exit
from threading import Thread
from time import monotonic

captureWarnings(True)
log = getLogger()
log.setLevel(INFO)
log.addHandler(StreamHandler())


@lru_cache(maxsize=1)
def _auth(user: str, now: int) -> bytes:
    parent = Path(__file__).parent
    argv = (
        parent / "oauth.sh",
        "--",
        Path.home() / ".local" / "state" / parent.name / f"{user}.oauth.gpg",
    )
    password = check_output(argv, text=True).rstrip()
    raw = f"user={user}\1auth=Bearer {password}\1\1"
    return raw.encode()


@contextmanager
def _imap(host: str, user: str) -> Iterator[IMAP4]:
    now = int(monotonic() / 60)
    auth = _auth(user, now=now)
    with IMAP4_SSL(host=host) as m:
        ok, _ = m.authenticate("XOAUTH2", lambda _: auth)
        assert ok == "OK", ok
        yield m


def _boxes(m: IMAP4) -> Iterator[bytes]:
    ok, data = m.list()
    assert ok == "OK", ok
    sep = b' "/" '
    for row in data:
        assert isinstance(row, bytes), row
        _, s, dir = row.partition(sep)
        assert s == sep, s
        yield dir


def _waiter(host: str, user: str, mailbox: str) -> Iterator[bytes]:
    with DefaultSelector() as sel, _imap(host, user=user) as m:
        sel.register(m.file, EVENT_READ)
        ok, _ = m.select(mailbox, readonly=True)
        assert ok == "OK", ok

        while True:
            tag = m._new_tag()
            assert isinstance(tag, bytes), tag
            m.send(tag + b" IDLE\r\n")
            line = m.readline()
            assert line.startswith(b"+ "), line

            try:
                if sel.select(60):
                    line = m.readline()
                    assert line.startswith(b"* "), line
                    line2 = m.readline()
                    assert line2.startswith(b"* "), line2
                    yield line
            finally:
                m.send(b"DONE\r\n")
                line = m.readline()
                assert line.startswith(tag + b" OK"), line


def _idle(host: str, user: str, mailbox: str) -> None:
    while True:
        try:
            for event in _waiter(host, user=user, mailbox=mailbox):
                print(event)
        except IMAP4.error as e:
            log.error("%s", e)


def _parse_args() -> Namespace:
    parser = ArgumentParser()
    parser.add_argument("--host", default="outlook.office365.com")
    parser.add_argument("username")
    return parser.parse_args()


def main() -> None:
    args = _parse_args()

    with _imap(args.host, user=args.username) as m:
        assert "IDLE" in m.capabilities
        boxes = tuple(_boxes(m))

    idle = partial(_idle, args.host, args.username)
    th = tuple(Thread(target=idle, args=(box,), daemon=True) for box in boxes)
    for t in th:
        t.start()
    for t in th:
        t.join()


try:
    main()
except KeyboardInterrupt:
    exit(130)
