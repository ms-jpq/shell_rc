#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from argparse import ArgumentParser, Namespace
from collections.abc import Iterator
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager, nullcontext
from functools import cache, lru_cache, partial
from imaplib import IMAP4, IMAP4_SSL, Commands
from logging import INFO, LogRecord, StreamHandler, captureWarnings, getLogger
from logging.handlers import SysLogHandler
from pathlib import Path
from platform import system
from selectors import EVENT_READ, DefaultSelector
from subprocess import check_output
from sys import exit
from syslog import openlog, syslog
from threading import Lock
from time import monotonic, sleep

_MINUTE = 60
_FILE = Path(__file__).resolve()

with nullcontext():
    captureWarnings(True)
    log = getLogger()
    log.setLevel(INFO)
    log.addHandler(StreamHandler())
    if system() == "Darwin":

        class _SysLogHandler(SysLogHandler):
            def emit(self, record: LogRecord) -> None:
                try:
                    pri = self.encodePriority(
                        self.facility,
                        self.mapPriority(record.levelname),
                    )
                    msg = self.format(record)
                except Exception:
                    self.handleError(record)
                else:
                    syslog(pri, msg)

        openlog(ident=_FILE.name)
        log.addHandler(_SysLogHandler())

with nullcontext():
    Commands["IDLE"] = ("SELECTED",)


@cache
def _lock() -> Lock:
    return Lock()


@lru_cache(maxsize=1)
def _auth(user: str, now: int) -> bytes:
    parent = _FILE.parent
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
    now = int(monotonic() / _MINUTE)
    with _lock():
        auth = _auth(user, now=now)

    with IMAP4_SSL(host=host) as m:
        ok, _ = m.authenticate("XOAUTH2", lambda _: auth)
        assert ok == "OK", ok
        yield m


def _boxes(m: IMAP4) -> Iterator[str]:
    ok, data = m.list()
    assert ok == "OK", ok
    sep = b' "/" '
    for row in data:
        assert isinstance(row, bytes), row
        _, s, dir = row.partition(sep)
        assert s == sep, s
        yield dir.decode()


# https://github.com/python/cpython/issues/55454
def _waiter(host: str, user: str, mailbox: str) -> Iterator[None]:
    with DefaultSelector() as sel, _imap(host, user=user) as m:
        assert "IDLE" in m.capabilities
        sel.register(m.file, EVENT_READ)

        ok, _ = m.select(mailbox, readonly=True)
        assert ok == "OK", ok

        while True:
            tag = m._command("IDLE")
            line = m.readline()
            assert line.startswith(b"+ "), line

            try:
                if sel.select(timeout=_MINUTE):
                    while line := m._get_line():
                        log.info("%s", f"{mailbox} -> {line}")
                        if line.endswith(b"EXISTS"):
                            yield None
            finally:
                m.send(b"DONE\r\n")
                m._command_complete("IDLE", tag)


def _trigger(channel: str) -> None:
    trigger = (
        Path.home()
        / ".local"
        / "state"
        / "isync"
        / f"mbsync.{channel}.watch"
        / "trigger"
    )
    trigger.touch()


def _idle(channel: str, host: str, user: str, mailbox: str) -> None:
    while True:
        try:
            for _ in _waiter(host, user=user, mailbox=mailbox):
                _trigger(channel)
        except IMAP4.error as e:
            log.exception("%s", e)
        finally:
            log.info("%s", f"    :: {mailbox}")
            sleep(3)


def _parse_args() -> Namespace:
    parser = ArgumentParser()
    parser.add_argument("--host", default="outlook.office365.com")
    parser.add_argument("--boxes", nargs="*", default=("INBOX",))
    parser.add_argument("channel")
    parser.add_argument("username")
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    idle = partial(_idle, args.channel, args.host, args.username)

    if not (boxes := args.boxes):
        with _imap(args.host, user=args.username) as m:
            boxes = tuple(_boxes(m))

    with ThreadPoolExecutor() as ex:
        tuple(ex.map(idle, boxes))


try:
    main()
except KeyboardInterrupt:
    exit(130)
except Exception as e:
    log.exception("%s", e)
    raise
